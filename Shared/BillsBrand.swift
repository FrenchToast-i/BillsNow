//
//  BillsBrand.swift
//  Shared
//
//  Team colors, shared look-and-feel helpers, and small SwiftUI views used by
//  both the main app and the widget extension.
//

import SwiftUI

public enum BillsBrand {
    public static let billsBlueHex = "00338D"
    public static let billsRedHex = "C8102E"
    public static let neutralGrayHex = "55606B"
    public static let whiteHex = "FFFFFF"

    /// Iconic two-tone palette per NFL abbreviation (primary, secondary).
    static let teamColors: [String: (String, String)] = [
        "ARI": ("97233F", "000000"),
        "ATL": ("A71930", "000000"),
        "BAL": ("241773", "9E7C0C"),
        "BUF": ("00338D", "C8102E"),
        "CAR": ("0085CA", "101820"),
        "CHI": ("0B162A", "C83803"),
        "CIN": ("FB4F14", "000000"),
        "CLE": ("311D00", "FF3C00"),
        "DAL": ("003594", "869397"),
        "DEN": ("FB4F14", "002244"),
        "DET": ("0076B6", "B0B7BC"),
        "GB":  ("203731", "FFB612"),
        "HOU": ("03202F", "A71930"),
        "IND": ("002C5F", "A2AAAD"),
        "JAX": ("006778", "D7A22A"),
        "KC":  ("E31837", "FFB81C"),
        "LAC": ("0080C6", "FFC20E"),
        "LAR": ("003594", "FFD100"),
        "LV":  ("000000", "A5ACAF"),
        "MIA": ("008E97", "FC4C02"),
        "MIN": ("4F2683", "FFB612"),
        "NE":  ("002244", "C60C30"),
        "NO":  ("101820", "D3BC8D"),
        "NYG": ("0B2265", "A71930"),
        "NYJ": ("125740", "7B8B6F"),
        "PHI": ("004C54", "A5ACAF"),
        "PIT": ("101820", "FFB612"),
        "SF":  ("AA0000", "B3995D"),
        "SEA": ("002244", "69BE28"),
        "TB":  ("D50A0A", "34302B"),
        "TEN": ("0C2340", "C8102E"),
        "WAS": ("5A1414", "FFB612"),
        "NFL": ("1F2937", "6B7280"),
    ]

    public struct TeamColors {
        public let primary: String
        public let secondary: String
    }

    public static func colors(forAbbreviation abbreviation: String) -> TeamColors {
        guard let pair = teamColors[abbreviation.uppercased()] else {
            return TeamColors(primary: neutralGrayHex, secondary: neutralGrayHex)
        }
        return TeamColors(primary: pair.0, secondary: pair.1)
    }

    public static var billsBlue: Color { Color(hex: billsBlueHex) }
    public static var billsRed: Color { Color(hex: billsRedHex) }
}

// MARK: - Color from hex

public extension Color {
    /// "RRGGBB" or "#RRGGBB"
    init(hex: String) {
        var value: UInt64 = 0
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Views

/// A colored disc with the team abbreviation. Used as a fast, always-working
/// stand-in for a team logo (and as the AsyncImage fallback).
public struct TeamBadge: View {
    public let abbreviation: String
    public let color: Color
    public var size: CGFloat = 44

    public init(abbreviation: String, color: Color, size: CGFloat = 44) {
        self.abbreviation = abbreviation
        self.color = color
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            Text(abbreviation)
                .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(2)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Team logo with a colored abbreviation disc as placeholder/failure state.
/// Uses AsyncImage (iOS 15+); in widgets the shared URL cache is typically
/// warm from the app, and the badge keeps the layout stable regardless.
public struct TeamLogo: View {
    public let team: TeamSide
    public var size: CGFloat = 44

    public init(team: TeamSide, size: CGFloat = 44) {
        self.team = team
        self.size = size
    }

    public var body: some View {
        let fallback = TeamBadge(abbreviation: team.abbreviation,
                                 color: Color(hex: team.colorHex),
                                 size: size)
        Group {
            if let urlString = team.logoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    fallback
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
