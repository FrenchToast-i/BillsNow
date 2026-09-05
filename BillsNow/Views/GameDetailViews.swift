//
//  GameDetailViews.swift
//  BillsNow
//

import SwiftUI

// MARK: - Section definition

enum GameSection: String, CaseIterable, Identifiable {
    case live = "Live"
    case scoring = "Scoring"
    case stats = "Stats"
    case roster = "Roster"

    var id: String { rawValue }
}

// MARK: - Scoring play row

struct ScoringPlayRow: View {
    let play: GameScoringPlay

    private var teamColorHex: String { BillsBrand.colors(forAbbreviation: play.teamAbbr).primary }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // quarter / clock column
            VStack(alignment: .leading, spacing: 2) {
                Text("Q\(play.quarter)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                Text(play.clock)
                    .font(.footnote.weight(.medium))
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            .frame(width: 42, alignment: .leading)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: teamColorHex))
                .frame(width: 3, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(play.teamAbbr)
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: teamColorHex).opacity(0.16), in: RoundedRectangle(cornerRadius: 5))
                        .foregroundColor(Color(hex: teamColorHex))
                    Text(shortTitle(play.title))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.primary)
                }
                Text(play.detail)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(play.awayScore)–\(play.homeScore)")
                    .font(.subheadline.weight(.heavy))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                Text("after")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Q\(play.quarter) \(play.clock), \(play.teamAbbr) \(shortTitle(play.title)). \(play.detail). Score \(play.awayScore) to \(play.homeScore)")
    }

    private func shortTitle(_ title: String) -> String {
        if title.localizedCaseInsensitiveContains("touchdown") { return "Touchdown" }
        if title.localizedCaseInsensitiveContains("field goal") { return "Field Goal" }
        if title.localizedCaseInsensitiveContains("safety") { return "Safety" }
        if title.localizedCaseInsensitiveContains("two") { return "2-Point" }
        return title
    }
}

// MARK: - Play-by-play row

struct PlayRow: View {
    let play: GamePlay

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if !play.clock.isEmpty {
                    Text(play.clock)
                        .font(.footnote.weight(.bold))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                }
                if let down = play.downText, !down.isEmpty {
                    Text(down)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 56, alignment: .leading)

            RoundedRectangle(cornerRadius: 2)
                .fill(barColor)
                .frame(width: 3, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let abbr = play.teamAbbr, !abbr.isEmpty {
                        Text(abbr)
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: teamColorHex).opacity(0.16),
                                        in: RoundedRectangle(cornerRadius: 5))
                            .foregroundColor(Color(hex: teamColorHex))
                    }
                    if play.isScoring {
                        Text("SCORE")
                            .font(.system(size: 9, weight: .black))
                            .tracking(0.5)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BillsBrand.billsRed, in: RoundedRectangle(cornerRadius: 5))
                            .foregroundColor(.white)
                    }
                }
                Text(play.text)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .lineLimit(4)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }

    private var teamColorHex: String {
        guard let abbr = play.teamAbbr else { return BillsBrand.neutralGrayHex }
        return BillsBrand.colors(forAbbreviation: abbr).primary
    }

    private var barColor: Color {
        guard let abbr = play.teamAbbr else { return Color.gray.opacity(0.35) }
        return Color(hex: BillsBrand.colors(forAbbreviation: abbr).primary)
    }
}

// MARK: - Generic info row (used for pre-game / meta info)

struct GameInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(BillsBrand.billsBlue)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Small empty-state

struct EmptyDetailRow: View {
    let icon: String
    let message: String

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 28)
            Spacer()
        }
    }
}
