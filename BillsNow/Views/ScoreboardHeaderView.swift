//
//  ScoreboardHeaderView.swift
//  BillsNow
//

import SwiftUI

/// The big navy game card at the top of the Game tab: matchup, live score,
/// clock/quarter, possession, down & distance, and the last play or
/// pre-game details.
struct ScoreboardHeaderView: View {
    let game: BillsGame

    var body: some View {
        VStack(spacing: 0) {
            statusRow
                .padding(.top, 12)
                .padding(.bottom, 8)

            TeamScoreRow(team: game.away,
                         possessionTeamID: game.possessionTeamID,
                         emphasized: game.isFinal && game.away.isWinner)
            thinDivider
            TeamScoreRow(team: game.home,
                         possessionTeamID: game.possessionTeamID,
                         emphasized: game.isFinal && game.home.isWinner)
                .padding(.bottom, game.isLive ? 2 : 10)

            if game.isLive {
                liveStrip
            }
            if game.isPre {
                preGameStrip
            }
            footer
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                LinearGradient(colors: [Color(hex: "001A3E"), Color(hex: "00338D")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                // subtle red energy line
                HStack(spacing: 0) {
                    Spacer()
                    Rectangle().fill(Color(hex: "C8102E").opacity(0.85))
                        .frame(width: 6)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
    }

    private var thinDivider: some View {
        Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
    }

    // MARK: Status row

    private var statusRow: some View {
        HStack(spacing: 10) {
            Text(game.away.abbreviation)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
            StatusPill(state: game.state, liveDetail: game.statusDetail)
                .frame(maxWidth: .infinity)
            Text(game.home.abbreviation)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: Live

    private var liveStrip: some View {
        HStack(spacing: 7) {
            Image(systemName: "football.fill")
                .font(.caption)
                .foregroundColor(Color(hex: "C8102E"))
            Text(centerLine)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.08), in: Capsule())
        .frame(maxWidth: .infinity)
    }

    private var centerLine: String {
        if let down = game.downDistanceText, !down.isEmpty { return down }
        if game.displayClock.isEmpty { return "Live" }
        return "Live · \(game.displayClock)"
    }

    private var preGameStrip: some View {
        HStack(spacing: 6) {
            if let odds = game.oddsLine, !odds.isEmpty {
                Text(odds)
            }
            if let weather = game.weatherText, !weather.isEmpty {
                if game.oddsLine != nil { Text("·") }
                Text(weather)
            }
        }
        .font(.footnote.weight(.medium))
        .foregroundColor(.white.opacity(0.92))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: Capsule())
    }

    // MARK: Footer

    @ViewBuilder
    private var footer: some View {
        if game.isLive, let lastPlay = game.lastPlayText, !lastPlay.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Label("Last play", systemImage: "play.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Color(hex: "C8102E"))
                Text(lastPlay)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if game.isPre, let kickoff = game.kickoff {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let venue = game.venueName {
                        infoLabel(venue, icon: "mappin.and.ellipse")
                    }
                    if game.venueName != nil, game.broadcast != nil { Text("·") }
                    if let broadcast = game.broadcast {
                        infoLabel(broadcast, icon: "tv")
                    }
                }
                CountdownRow(kickoff: kickoff)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Final: keep the card tidy
            HStack(spacing: 10) {
                if let venue = game.venueName {
                    infoLabel(venue, icon: "mappin.and.ellipse")
                }
                if let broadcast = game.broadcast {
                    infoLabel(broadcast, icon: "tv")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func infoLabel(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundColor(.white.opacity(0.75))
    }
}

// MARK: - Team row

struct TeamScoreRow: View {
    let team: TeamSide
    let possessionTeamID: String?
    let emphasized: Bool

    var body: some View {
        HStack(spacing: 12) {
            TeamLogo(team: team, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(team.shortName)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    if possessionTeamID == team.teamID {
                        Text("O")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "C8102E"), in: RoundedRectangle(cornerRadius: 4))
                            .accessibilityLabel("on offense")
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Text("\(team.score)")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(emphasized ? Color(hex: "FFD100") : .white)
                .accessibilityLabel("\(team.shortName) \(team.score)")
        }
        .padding(.vertical, 8)
    }

    private var subtitle: String {
        var parts = [String]()
        if team.isHome { parts.append("Home") } else { parts.append("Away") }
        if let record = team.record, !record.isEmpty { parts.append(record) }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Status pill

struct StatusPill: View {
    let state: GameState
    let liveDetail: String

    var body: some View {
        HStack(spacing: 6) {
            switch state {
            case .live:
                LiveDot()
                Text("LIVE")
            case .pre:
                Image(systemName: "calendar")
                    .font(.caption2)
                Text(liveDetail.isEmpty ? "UPCOMING" : shortUpcoming(liveDetail))
            case .final:
                Text("FINAL")
            case .canceled:
                Text("CANCELED")
            }
        }
        .font(.system(size: 12, weight: .black))
        .tracking(1)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(pillColor, in: Capsule())
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private var pillColor: Color {
        switch state {
        case .live: return Color(hex: "C8102E")
        case .pre: return Color.white.opacity(0.18)
        case .final: return Color.white.opacity(0.22)
        case .canceled: return Color.white.opacity(0.22)
        }
    }

    private func shortUpcoming(_ detail: String) -> String {
        // "Sun, September 13th at 1:00 PM EDT" -> "SUN 1:00 PM"
        let lower = detail.lowercased()
        let pieces = lower.components(separatedBy: " at ")
        guard pieces.count == 2 else { return detail.uppercased() }
        let day = String(pieces[0].prefix(3)).uppercased()
        let time = pieces[1].replacingOccurrences(of: "m", with: "M")
        return "\(day) \(time)"
    }
}

struct LiveDot: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 6, height: 6)
            .opacity(pulse ? 1 : 0.35)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                       value: pulse)
            .onAppear { pulse = true }
    }
}

// MARK: - Kickoff countdown

struct CountdownRow: View {
    let kickoff: Date

    var body: some View {
        let remaining = kickoff.timeIntervalSince(Date())
        if remaining > 0 {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("Kickoff in \(countdown(remaining))")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
        } else {
            Text("Game starts soon — tap refresh to catch the action")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private func countdown(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(max(minutes, 0))m"
    }
}
