//
//  GameView.swift
//  BillsNow
//

import SwiftUI

struct GameView: View {
    @StateObject private var vm: GameViewModel
    @State private var section: GameSection = .live

    init(previewGame: BillsGame? = nil) {
        _vm = StateObject(wrappedValue: GameViewModel(previewGame: previewGame))
    }

    var body: some View {
        Group {
            if let game = vm.game {
                gameContent(game)
            } else if vm.isLoading {
                loadingView
            } else {
                idleView
            }
        }
        .navigationTitle("Buffalo Bills")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Button(action: { Task { await vm.refresh() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh game")
                }
            }
        }
        .task { await vm.runLoop() }
    }

    // MARK: Content

    private func gameContent(_ game: BillsGame) -> some View {
        VStack(spacing: 0) {
            ScoreboardHeaderView(game: game)
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 4)

            if !game.isPre {
                Picker("Game section", selection: $section) {
                    ForEach(GameSection.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .onChange(of: game.state) { state in
                    if state == .pre { return }
                    if section == .live && game.plays.isEmpty && !game.scoringPlays.isEmpty {
                        section = .scoring
                    }
                }
            }

            detailList(game)
        }
    }

    @ViewBuilder
    private func detailList(_ game: BillsGame) -> some View {
        List {
            Group {
                if game.isPre {
                    preGameRows(game)
                } else {
                    switch section {
                    case .live: liveRows(game)
                    case .scoring: scoringRows(game)
                    case .stats: statsRows(game)
                    case .roster: rosterRows(game)
                    }
                }
            }

            Section {
                updatedFooter(game)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable { await vm.refresh() }
    }

    // MARK: Live

    @ViewBuilder
    private func liveRows(_ game: BillsGame) -> some View {
        if game.plays.isEmpty {
            EmptyDetailRow(icon: "bolt.horizontal.circle",
                           message: "Play-by-play isn't available for this one yet.")
                .padding(.vertical, 10)
        } else {
            Section {
                ForEach(game.plays) { play in
                    PlayRow(play: play)
                }
            } header: {
                Text(game.isLive ? "LIVE FEED" : "GAME FEED")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundColor(BillsBrand.billsRed)
            } footer: {
                Text(game.isLive
                     ? "Auto-refreshes every 30 seconds during the game."
                     : "Drive-by-drive recap.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func scoringRows(_ game: BillsGame) -> some View {
        if game.scoringPlays.isEmpty {
            EmptyDetailRow(icon: "trophy",
                           message: game.isPre
                               ? "Scoring will appear once the game starts."
                               : "No scoring plays recorded.")
        } else {
            Section {
                ForEach(game.scoringPlays) { play in
                    ScoringPlayRow(play: play)
                }
            } header: {
                Text("SCORING SUMMARY")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundColor(BillsBrand.billsBlue)
            }
        }
    }

    @ViewBuilder
    private func statsRows(_ game: BillsGame) -> some View {
        if game.awayStats.isEmpty && game.homeStats.isEmpty && game.playerGroups.isEmpty {
            EmptyDetailRow(icon: "chart.bar",
                           message: game.isPre
                               ? "Stats will appear once the game starts."
                               : "No stats available.")
                .padding(.vertical, 10)
        } else {
            if !game.awayStats.isEmpty && !game.homeStats.isEmpty {
                TeamStatsTable(away: game.away, home: game.home,
                               awayStats: game.awayStats, homeStats: game.homeStats)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)
            }
            PlayerLeadersView(game: game)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.bottom, 6)
        }
    }

    @ViewBuilder
    private func rosterRows(_ game: BillsGame) -> some View {
        RosterView(away: game.away, home: game.home,
                   awayRoster: game.awayRoster, homeRoster: game.homeRoster)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .padding(.vertical, 6)
    }

    // MARK: Pre-game

    @ViewBuilder
    private func preGameRows(_ game: BillsGame) -> some View {
        Section {
            if let kickoff = game.kickoff {
                GameInfoRow(icon: "calendar",
                            title: "Kickoff",
                            value: GameFormat.fullKickoff.string(from: kickoff))
            }
            if game.billsSide?.record != nil {
                GameInfoRow(icon: "chart.line.uptrend.xyaxis",
                            title: "Records",
                            value: "\(game.away.shortName) \(game.away.record ?? "–") vs \(game.home.shortName) \(game.home.record ?? "–")")
            }
            if let venue = game.venueName {
                let place = venue + (game.venueCity.map { " · \($0)" } ?? "")
                GameInfoRow(icon: "mappin.and.ellipse", title: "Venue", value: place)
            }
            if let broadcast = game.broadcast {
                GameInfoRow(icon: "tv", title: "TV", value: broadcast)
            }
            if let odds = game.oddsLine {
                GameInfoRow(icon: "dollarsign.circle", title: "Odds", value: odds)
            }
            if let weather = game.weatherText {
                GameInfoRow(icon: "cloud.sun", title: "Weather", value: weather)
            }
        } header: {
            Text("GAME DAY")
                .font(.caption.weight(.heavy))
                .tracking(1)
                .foregroundColor(BillsBrand.billsBlue)
        }

        if !game.scoringPlays.isEmpty {
            Section {
                ForEach(game.scoringPlays) { play in
                    ScoringPlayRow(play: play)
                }
            } header: {
                Text("LAST MEETING")
                    .font(.caption.weight(.heavy))
                    .tracking(1)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: Footer / states

    private func updatedFooter(_ game: BillsGame) -> some View {
        HStack {
            Spacer()
            Text("Updated \(GameFormat.relativeUpdate(game.fetchedAt)) · via ESPN")
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("Looking for the next Bills game…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var idleView: some View {
        VStack(spacing: 14) {
            Image(systemName: "football")
                .font(.system(size: 42))
                .foregroundColor(BillsBrand.billsBlue)
            Text(vm.errorMessage ?? "Couldn't reach the stats feed.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Try again") {
                Task { await vm.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
