//
//  WidgetViews.swift
//  BillsWidget
//
//  Live-score widget UI. Designed on the Bills navy/red palette to read like
//  a scorebug: matchup rows, live clock, possession, down & distance, and a
//  last-play / scoring summary footer.
//

import SwiftUI
import WidgetKit

// MARK: - Palette & shared chrome

enum WidgetPalette {
    static let navyTop = Color(hex: "0A1F4B")
    static let navyBottom = Color(hex: "00338D")
    static let red = Color(hex: "C8102E")
    static let gold = Color(hex: "FFD100")
    static let white = Color.white
    static let whiteDim = Color.white.opacity(0.62)
    static let whiteFaint = Color.white.opacity(0.38)

    static var background: some View {
        LinearGradient(colors: [navyTop, navyBottom],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }
}

extension View {
    /// iOS 17+ widgets render the container background edge-to-edge and let
    /// the system clip corners. On iOS 15/16 a plain `.background` is used,
    /// which fills the widget bounds the same way.
    @ViewBuilder
    func widgetBackgroundCompat() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) { WidgetPalette.background }
        } else {
            self.background(WidgetPalette.background)
        }
    }
}

// MARK: - Entry

struct ScoreEntry: TimelineEntry {
    let date: Date
    let game: BillsGame?
}

// MARK: - Root widget view

struct BillsLiveScoreWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ScoreEntry

    var body: some View {
        Group {
            if let game = entry.game {
                switch family {
                case .systemSmall:
                    SmallScoreView(game: game, updatedAt: entry.date)
                case .systemMedium:
                    WideScoreView(game: game, updatedAt: entry.date, showScoring: false)
                default:
                    WideScoreView(game: game, updatedAt: entry.date, showScoring: true)
                }
            } else {
                NoGameView()
            }
        }
        .widgetBackgroundCompat()
        .widgetURL(URL(string: "billsnow://game"))
    }
}

// MARK: - Small

private struct SmallScoreView: View {
    let game: BillsGame
    let updatedAt: Date

    var body: some View {
        VStack(spacing: 7) {
            statusHeader
            teamRow(game.away)
            teamRow(game.home)
            Spacer(minLength: 0)
            footer
        }
        .padding(12)
    }

    private var statusHeader: some View {
        HStack(spacing: 5) {
            StatusChip(game: game)
                .fixedSize()
            Text(statusMiddle)
                .font(.caption2.weight(.bold))
                .foregroundColor(WidgetPalette.whiteDim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusMiddle: String {
        switch game.state {
        case .live: return game.displayClock
        case .pre: return "KICKOFF"
        case .final: return game.statusDetail.uppercased()
        case .canceled: return ""
        }
    }

    private func teamRow(_ team: TeamSide) -> some View {
        HStack(spacing: 8) {
            TeamLogo(team: team, size: 24)
            Text(team.shortName)
                .font(.caption.weight(.bold))
                .foregroundColor(WidgetPalette.white)
                .lineLimit(1)
            if game.isLive && game.possessionTeamID == team.teamID {
                Circle()
                    .fill(WidgetPalette.red)
                    .frame(width: 5, height: 5)
            }
            Spacer(minLength: 4)
            Text(scoreText(team))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(scoreColor(team))
        }
        .accessibilityElement(children: .combine)
    }

    private func scoreText(_ team: TeamSide) -> String {
        game.isPre ? "–" : "\(team.score)"
    }

    private func scoreColor(_ team: TeamSide) -> Color {
        if game.isFinal && team.isWinner { return WidgetPalette.gold }
        return WidgetPalette.white
    }

    @ViewBuilder
    private var footer: some View {
        switch game.state {
        case .live:
            if let down = game.downDistanceText, !down.isEmpty {
                Text(down)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(WidgetPalette.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text(relativeUpdate)
                    .font(.caption2)
                    .foregroundColor(WidgetPalette.whiteFaint)
            }
        case .pre:
            Text(preLine)
                .font(.caption2.weight(.semibold))
                .foregroundColor(WidgetPalette.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        case .final:
            if let detail = game.lastPlayText ?? game.scoringPlays.last?.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(WidgetPalette.whiteDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text(relativeUpdate).font(.caption2).foregroundColor(WidgetPalette.whiteFaint)
            }
        case .canceled:
            Text(relativeUpdate).font(.caption2).foregroundColor(WidgetPalette.whiteFaint)
        }
    }

    private var preLine: String {
        if let odds = game.oddsLine, !odds.isEmpty { return odds }
        if let kickoff = game.kickoff { return GameFormat.fullKickoff.string(from: kickoff) }
        return "Scheduled"
    }

    private var relativeUpdate: String {
        GameFormat.relativeUpdate(game.fetchedAt, now: updatedAt)
    }
}

// MARK: - Medium & Large

private struct WideScoreView: View {
    let game: BillsGame
    let updatedAt: Date
    let showScoring: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                StatusChip(game: game)
                statusMeta
                    .frame(maxWidth: .infinity)
                if game.isLive, let down = game.downDistanceText, !down.isEmpty {
                    Text(down)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(WidgetPalette.white.opacity(0.95))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.bottom, 6)

            TeamRowLarge(team: game.away, game: game)
            divider
            TeamRowLarge(team: game.home, game: game)

            if showScoring {
                scoringBlock
            } else {
                wideFooter
            }
        }
        .padding(14)
    }

    private var statusMeta: String {
        switch game.state {
        case .live: return game.displayClock
        case .pre: return "\(game.away.abbreviation) @ \(game.home.abbreviation)"
        case .final: return game.statusDetail.uppercased()
        case .canceled: return "CANCELED"
        }
    }

    private var divider: some View {
        Rectangle().fill(WidgetPalette.white.opacity(0.14)).frame(height: 1)
            .padding(.leading, 34)
    }

    @ViewBuilder
    private var wideFooter: some View {
        HStack(spacing: 6) {
            switch game.state {
            case .live:
                if let play = game.lastPlayText, !play.isEmpty {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8))
                        .foregroundColor(WidgetPalette.red)
                    Text(play)
                        .font(.caption2)
                        .foregroundColor(WidgetPalette.white.opacity(0.9))
                        .lineLimit(2)
                } else {
                    Text(relativeUpdate).font(.caption2).foregroundColor(WidgetPalette.whiteFaint)
                }
            case .pre:
                if let odds = game.oddsLine, !odds.isEmpty {
                    Text(odds).font(.caption.weight(.bold)).foregroundColor(WidgetPalette.white.opacity(0.9))
                }
                if let kickoff = game.kickoff {
                    Text(GameFormat.fullKickoff.string(from: kickoff))
                        .font(.caption2)
                        .foregroundColor(WidgetPalette.whiteDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            case .final:
                if let detail = game.scoringPlays.last?.detail ?? game.lastPlayText {
                    Text(detail)
                        .font(.caption2)
                        .foregroundColor(WidgetPalette.whiteDim)
                        .lineLimit(2)
                } else {
                    Text(relativeUpdate).font(.caption2).foregroundColor(WidgetPalette.whiteFaint)
                }
            case .canceled:
                Text("Game canceled").font(.caption2).foregroundColor(WidgetPalette.whiteDim)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 5)
    }

    @ViewBuilder
    private var scoringBlock: some View {
        if game.scoringPlays.isEmpty {
            wideFooter
        } else {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SCORING")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                        .foregroundColor(WidgetPalette.red)
                        .padding(.top, 2)
                    ForEach(game.scoringPlays.suffix(4)) { play in
                        ScoringChipRow(play: play)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    if let last = game.lastPlayText, !last.isEmpty {
                        Text("LAST PLAY")
                            .font(.system(size: 9, weight: .black))
                            .tracking(1)
                            .foregroundColor(WidgetPalette.whiteFaint)
                            .padding(.top, 2)
                        Text(last)
                            .font(.caption2)
                            .foregroundColor(WidgetPalette.white.opacity(0.85))
                            .lineLimit(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Text(relativeUpdate)
                        .font(.system(size: 9))
                        .foregroundColor(WidgetPalette.whiteFaint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 6)
        }
    }

    private var relativeUpdate: String {
        GameFormat.relativeUpdate(game.fetchedAt, now: updatedAt)
    }
}

private struct TeamRowLarge: View {
    let team: TeamSide
    let game: BillsGame

    var body: some View {
        HStack(spacing: 10) {
            TeamLogo(team: team, size: 26)
            Text(team.shortName.uppercased())
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(0.4)
                .foregroundColor(WidgetPalette.white)
                .lineLimit(1)
            if let record = team.record, !record.isEmpty {
                Text(record)
                    .font(.caption2)
                    .foregroundColor(WidgetPalette.whiteFaint)
                    .lineLimit(1)
            }
            if game.isLive && game.possessionTeamID == team.teamID {
                Circle().fill(WidgetPalette.red).frame(width: 6, height: 6)
            }
            Spacer(minLength: 4)
            Text(game.isPre ? "–" : "\(team.score)")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(team.isWinner && game.isFinal ? WidgetPalette.gold : WidgetPalette.white)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}

private struct ScoringChipRow: View {
    let play: GameScoringPlay

    var body: some View {
        HStack(spacing: 6) {
            Text("Q\(play.quarter) \(play.clock)")
                .font(.system(size: 9, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(WidgetPalette.whiteFaint)
                .frame(width: 40, alignment: .leading)
            Text(play.teamAbbr)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(Color(hex: BillsBrand.colors(forAbbreviation: play.teamAbbr).primary))
            Text(play.detail)
                .font(.system(size: 10))
                .foregroundColor(WidgetPalette.white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - Status chip

private struct StatusChip: View {
    let game: BillsGame

    var body: some View {
        HStack(spacing: 4) {
            switch game.state {
            case .live:
                Circle().fill(WidgetPalette.white).frame(width: 5, height: 5)
                Text("LIVE")
            case .pre:
                Text("UPCOMING")
            case .final:
                Text("FINAL")
            case .canceled:
                Text("CANCELED")
            }
        }
        .font(.system(size: 9, weight: .black))
        .tracking(0.8)
        .foregroundColor(WidgetPalette.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(chipBackground, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .accessibilityLabel(chipAccessibility)
    }

    private var chipBackground: Color {
        switch game.state {
        case .live: return WidgetPalette.red
        case .pre: return WidgetPalette.white.opacity(0.16)
        case .final, .canceled: return WidgetPalette.white.opacity(0.2)
        }
    }

    private var chipAccessibility: String {
        switch game.state {
        case .live: return "Live game, \(game.displayClock)"
        case .pre: return "Upcoming game"
        case .final: return "Final"
        case .canceled: return "Canceled"
        }
    }
}

// MARK: - No game

private struct NoGameView: View {
    var body: some View {
        VStack(spacing: 8) {
            TeamBadge(abbreviation: "BUF",
                      color: Color(hex: BillsBrand.billsBlueHex), size: 40)
            Text("No Bills game right now")
                .font(.footnote.weight(.bold))
                .foregroundColor(WidgetPalette.white)
                .multilineTextAlignment(.center)
            Text("Open BillsNow to see the schedule")
                .font(.caption2)
                .foregroundColor(WidgetPalette.whiteDim)
                .multilineTextAlignment(.center)
        }
        .padding(12)
    }
}
