//
//  StatsAndRosterViews.swift
//  BillsNow
//

import SwiftUI

// MARK: - Team stat table

/// Aligns each team's stat blocks by label and renders key stats first.
struct TeamStatsTable: View {
    let away: TeamSide
    let home: TeamSide
    let awayStats: [GameStat]
    let homeStats: [GameStat]

    private let preferredOrder = [
        "Total Yards", "Rushing", "Passing", "1st Downs", "3rd Down Conv",
        "Turnovers", "Possession", "Penalties", "Sacks", "Red Zone",
    ]

    private var rows: [(String, String, String)] {
        let homeByLabel = Dictionary(homeStats.map { ($0.label, $0.value) }, uniquingKeysWith: { a, _ in a })
        let awayByLabel = Dictionary(awayStats.map { ($0.label, $0.value) }, uniquingKeysWith: { a, _ in a })
        let labels = Array(Set(awayByLabel.keys).union(homeByLabel.keys))

        let keyed = labels.filter { homeByLabel[$0] != nil && awayByLabel[$0] != nil }
        let sorted = keyed.sorted { a, b in
            let ai = preferredOrder.firstIndex { a.localizedCaseInsensitiveContains($0) } ?? 999
            let bi = preferredOrder.firstIndex { b.localizedCaseInsensitiveContains($0) } ?? 999
            if ai != bi { return ai < bi }
            return a < b
        }
        return sorted.map { ($0, awayByLabel[$0] ?? "–", homeByLabel[$0] ?? "–") }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TeamMiniLabel(side: away)
                TeamMiniLabel(side: home)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 12) {
                    Text(row.0)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.1)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .frame(width: 70, alignment: .center)
                    Text(row.2)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .frame(width: 70, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                Divider().opacity(0.5)
            }
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }
}

private struct TeamMiniLabel: View {
    let side: TeamSide

    var body: some View {
        HStack(spacing: 5) {
            TeamLogo(team: side, size: 16)
            Text(side.abbreviation)
                .font(.caption.weight(.bold))
        }
        .frame(width: 70, alignment: .center)
        .accessibilityHidden(true)
    }
}

// MARK: - Player leaders

struct PlayerLeadersView: View {
    let game: BillsGame

    var body: some View {
        let billsGroups = game.playerGroups.filter { $0.teamID == game.billsSide?.teamID }
        let oppGroups = game.playerGroups.filter { $0.teamID == game.opponent?.teamID }

        VStack(spacing: 14) {
            if billsGroups.isEmpty && oppGroups.isEmpty {
                EmptyDetailRow(icon: "chart.bar", message: "Player stats will appear once the game gets going.")
            } else {
                if !billsGroups.isEmpty, let side = game.billsSide {
                    statBlock(title: "\(side.shortName) leaders", accent: Color(hex: side.colorHex),
                              groups: billsGroups)
                }
                if !oppGroups.isEmpty, let side = game.opponent {
                    statBlock(title: "\(side.shortName) leaders", accent: Color(hex: side.colorHex),
                              groups: oppGroups)
                }
            }
        }
    }

    private func statBlock(title: String, accent: Color, groups: [PlayerStatGroup]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(1.2)
                .foregroundColor(accent)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name.capitalized)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)
                    if !group.labels.isEmpty {
                        HStack {
                            Text("Player")
                            Spacer()
                            Text(group.labels.joined(separator: " "))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                    }
                    ForEach(Array(group.rows.prefix(6).enumerated()), id: \.offset) { _, row in
                        PlayerStatRowView(row: row)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

private struct PlayerStatRowView: View {
    let row: PlayerStatRow

    var body: some View {
        HStack(spacing: 8) {
            if let url = row.headshotURL.flatMap(URL.init(string:)) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.25)
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
            } else {
                Circle().fill(Color.gray.opacity(0.25)).frame(width: 24, height: 24)
            }
            Text(row.name)
                .font(.subheadline)
                .lineLimit(1)
            if let position = row.position {
                Text(position)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                    .frame(width: 26, alignment: .leading)
            }
            Spacer()
            Text(row.stats.joined(separator: " "))
                .font(.footnote.weight(.medium))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Roster

struct RosterView: View {
    let away: TeamSide
    let home: TeamSide
    let awayRoster: [RosterEntry]
    let homeRoster: [RosterEntry]

    @State private var showBills = true

    private static let positionOrder = [
        "QB", "RB", "FB", "WR", "TE", "OL", "C", "G", "T", "OT",
        "DL", "DE", "DT", "NT", "EDGE",
        "LB", "ILB", "OLB", "MLB",
        "DB", "CB", "S", "FS", "SS",
        "K", "P", "LS",
    ]

    var body: some View {
        let bills = home.isBills ? homeRoster : awayRoster
        let opp = home.isBills ? awayRoster : homeRoster
        let active = showBills ? bills : opp
        let activeSide = showBills ? (home.isBills ? home : away) : (home.isBills ? away : home)

        VStack(spacing: 6) {
            Picker("Team", selection: $showBills) {
                Text("Bills").tag(true)
                Text((home.isBills ? away : home).shortName).tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if active.isEmpty {
                EmptyDetailRow(icon: "person.3",
                               message: "Rosters appear here once the season kicks off.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(positionedRoster(active, for: activeSide)) { section in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(section.position.uppercased())
                                    .font(.caption2.weight(.black))
                                    .tracking(1)
                                    .foregroundColor(Color(hex: activeSide.colorHex))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(hex: activeSide.colorHex).opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                ForEach(section.players) { player in
                                    RosterPlayerCell(player: player)
                                }
                            }
                            .frame(width: 168)
                            .background(Color(.secondarySystemBackground),
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .accessibilityLabel("Roster by position")
            }
        }
    }

    private struct PositionSection: Identifiable {
        let position: String
        let players: [RosterEntry]
        var id: String { position }
    }

    private func positionedRoster(_ roster: [RosterEntry], for side: TeamSide) -> [PositionSection] {
        let grouped = Dictionary(grouping: roster) { $0.position }
        let known = grouped.filter { Self.positionOrder.contains($0.key) }
        let rest = grouped.filter { !Self.positionOrder.contains($0.key) }

        var sections: [PositionSection] = []
        for position in Self.positionOrder {
            if let players = known[position] {
                sections.append(PositionSection(position: position, players: sorted(players)))
            }
        }
        for (position, players) in rest {
            sections.append(PositionSection(position: position.isEmpty ? "?" : position,
                                            players: sorted(players)))
        }
        return sections
    }

    private func sorted(_ players: [RosterEntry]) -> [RosterEntry] {
        players.sorted {
            (Int($0.jersey) ?? 999) < (Int($1.jersey) ?? 999)
        }
    }
}

private struct RosterPlayerCell: View {
    let player: RosterEntry

    var body: some View {
        HStack(spacing: 8) {
            Text(player.jersey)
                .font(.footnote.weight(.bold))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(width: 26, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                    if player.isStarter {
                        Text("★")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                Text(player.position)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
