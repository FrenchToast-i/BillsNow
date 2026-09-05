//
//  BillsGame.swift
//  Shared
//
//  Compact, fully Codable domain snapshot of "the Bills game right now".
//  Both the app and the widget extension build and render this single type,
//  and it can be archived to the shared App Group container so the widget
//  can show the last known state instantly (or offline).
//

import Foundation

public enum GameState: String, Codable {
    case pre      // scheduled / upcoming
    case live     // in progress
    case final
    case canceled
}

// MARK: - Team side

public struct TeamSide: Codable, Equatable, Identifiable {
    public var id: String { teamID }
    public let teamID: String
    public let abbreviation: String
    public let shortName: String        // "Bills"
    public let displayName: String      // "Buffalo Bills"
    public let record: String?          // "3-2"
    public let score: Int
    public let isWinner: Bool
    public let isHome: Bool
    public let colorHex: String
    public let accentHex: String
    public let logoURL: String?

    public var isBills: Bool { teamID == BillsGame.billsTeamID }
}

// MARK: - Events inside a game

public struct GameScoringPlay: Codable, Equatable, Identifiable {
    public var id: String { uniqueID }
    public let uniqueID: String
    public let quarter: Int
    public let clock: String
    public let teamID: String
    public let teamAbbr: String
    public let title: String            // "Passing Touchdown"
    public let detail: String           // "Dalton Kincaid 15 Yd pass from Josh Allen (Tyler Bass Kick)"
    public let awayScore: Int
    public let homeScore: Int
}

public struct GamePlay: Codable, Equatable, Identifiable {
    public var id: String { uniqueID }
    public let uniqueID: String
    public let quarter: Int
    public let clock: String
    public let teamID: String?
    public let teamAbbr: String?
    public let isScoring: Bool
    public let downText: String?        // "1st & 10"
    public let text: String
}

public struct GameDrive: Codable, Equatable, Identifiable {
    public var id: String { uniqueID }
    public let uniqueID: String
    public let teamID: String
    public let teamAbbr: String
    public let description: String      // "7 plays, 50 yards, 3:41"
}

public struct GameStat: Codable, Equatable {
    public let label: String            // "Total Yards"
    public let value: String            // "342"
    public let isKey: Bool
}

/// Per-team player stat groups: passing / rushing / receiving / ...
public struct PlayerStatGroup: Codable, Equatable, Identifiable {
    public var id: String { teamID + ":" + name }
    public let teamID: String
    public let teamAbbr: String
    public let name: String             // "passing"
    public let labels: [String]
    public let rows: [PlayerStatRow]
}

public struct PlayerStatRow: Codable, Equatable {
    public let name: String
    public let position: String?        // "QB"
    public let jersey: String
    public let stats: [String]
    public let headshotURL: String?
}

public struct RosterEntry: Codable, Equatable, Identifiable {
    public var id: String { (athleteID ?? name) + position }
    public let athleteID: String?
    public let name: String
    public let position: String       // "QB", "WR", "ILB", ...
    public let jersey: String
    public let isStarter: Bool
    public let headshotURL: String?
}

// MARK: - The game

public struct BillsGame: Codable, Equatable, Identifiable {
    public static let billsTeamID = "2"

    public var id: String { eventID }

    public let eventID: String
    public let kickoff: Date?
    public let state: GameState
    public let statusDetail: String     // "Q2 8:12" | "Final" | "9/13 1:00 PM"
    public let quarter: Int?
    public let clock: String?           // "8:12"

    public let away: TeamSide
    public let home: TeamSide

    public let possessionTeamID: String?    // team with the ball (live only)
    public let downDistanceText: String?    // "3rd & 7 at BUF 42" (live only)
    public let lastPlayText: String?

    public let venueName: String?
    public let venueCity: String?
    public let broadcast: String?
    public let oddsLine: String?
    public let weatherText: String?

    public let scoringPlays: [GameScoringPlay]
    public let plays: [GamePlay]            // newest first when available
    public let drives: [GameDrive]
    public let awayStats: [GameStat]
    public let homeStats: [GameStat]
    public let playerGroups: [PlayerStatGroup]
    public let awayRoster: [RosterEntry]
    public let homeRoster: [RosterEntry]

    public let fetchedAt: Date

    public var billsSide: TeamSide? { home.isBills ? home : (away.isBills ? away : nil) }
    public var opponent: TeamSide? { home.isBills ? away : home }

    public var isBillsHome: Bool { home.isBills }
    public var isPre: Bool { state == .pre }
    public var isLive: Bool { state == .live }
    public var isFinal: Bool { state == .final || state == .canceled }

    public var displayClock: String {
        guard let clock = clock, !clock.isEmpty else { return "" }
        let q = quarter.map { "Q\($0)" } ?? ""
        return q.isEmpty ? clock : "\(q) \(clock)"
    }

    public var scoreline: String { "\(away.abbreviation) \(away.score) – \(home.abbreviation) \(home.score)" }
}

// MARK: - Formatters

public enum GameFormat {
    public static let fullKickoff: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d • h:mm a"
        return f
    }()

    /// "Q2 8:12" for live games, absolute kickoff time for scheduled games.
    public static func clockLine(for game: BillsGame) -> String {
        switch game.state {
        case .live:
            return game.displayClock
        case .pre:
            if let kickoff = game.kickoff {
                return fullKickoff.string(from: kickoff)
            }
            return "Scheduled"
        case .final:
            return "Final"
        case .canceled:
            return "Canceled"
        }
    }

    public static func relativeUpdate(_ date: Date, now: Date = Date()) -> String {
        let secs = max(0, now.timeIntervalSince(date))
        if secs < 60 { return "just now" }
        let mins = Int(secs / 60)
        if mins < 60 { return "\(mins)m ago" }
        let hours = Int(mins / 60)
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

// MARK: - Assembly from wire models

extension BillsGame {
    /// Picks a kickoff date from either an ISO8601 `date` string or an epoch
    /// string, whichever the endpoint supplied.
    static func date(from value: String?) -> Date? {
        guard let value = value, !value.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: value) { return d }
        if let n = Double(value) {
            let t = n > 1_000_000_000_000 ? n / 1000.0 : n
            return Date(timeIntervalSince1970: t)
        }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value)
    }

    static func teamSide(from competitor: Competitor, brand: BillsBrand.TeamColors, fallbackAbbreviation: String) -> TeamSide {
        let team = competitor.team
        let abbr = team?.abbreviation ?? fallbackAbbreviation
        return TeamSide(
            teamID: team?.id ?? "0",
            abbreviation: abbr,
            shortName: team?.shortDisplayName ?? team?.name ?? abbr,
            displayName: team?.displayName ?? abbr,
            record: competitor.record?.first { $0.type == "total" }?.summary,
            score: Int(competitor.score ?? "") ?? 0,
            isWinner: competitor.winner ?? false,
            isHome: competitor.homeAway == "home",
            colorHex: brand.primary,
            accentHex: brand.secondary,
            logoURL: team?.logos?.first { $0.rel?.contains("dark") == true }?.href
                ?? team?.logos?.first?.href
                ?? team?.logo
        )
    }

    /// Builds the domain snapshot from a parsed summary.
    public static func build(from summary: GameSummary, eventID: String) -> BillsGame {
        let competition = summary.header?.competitions?.first
        let competitors = competition?.competitors ?? []
        let status = competition?.status?.type
        let stateValue = status?.state ?? "post"

        let rawState: GameState
        switch stateValue {
        case "pre": rawState = .pre
        case "in": rawState = .live
        default:
            let name = status?.name ?? ""
            rawState = (name.contains("CANCELED") || name.contains("POSTPONED") || name.contains("SUSPENDED"))
                ? .canceled : .final
        }

        var homeSide: TeamSide?
        var awaySide: TeamSide?
        for comp in competitors {
            let isBills = comp.team?.id == Self.billsTeamID
            let fallbackAbbr = isBills ? "BUF" : "OPP"
            let brand = BillsBrand.colors(forAbbreviation: comp.team?.abbreviation ?? fallbackAbbr)
            let side = teamSide(from: comp, brand: brand, fallbackAbbreviation: fallbackAbbr)
            if comp.homeAway == "home" { homeSide = side } else { awaySide = side }
        }
        let blank = BillsBrand.colors(forAbbreviation: "NFL")
        let home = homeSide ?? TeamSide(teamID: "0", abbreviation: "HOME", shortName: "Home", displayName: "Home Team", record: nil, score: 0, isWinner: false, isHome: true, colorHex: blank.primary, accentHex: blank.secondary, logoURL: nil)
        let away = awaySide ?? TeamSide(teamID: "0", abbreviation: "AWAY", shortName: "Away", displayName: "Away Team", record: nil, score: 0, isWinner: false, isHome: false, colorHex: blank.primary, accentHex: blank.secondary, logoURL: nil)

        // Situation / possession: prefer competition.situation, then derive
        // from the most recent play's field position.
        let situation = competition?.situation
        var possessionID = situation?.possession ?? situation?.ball
        var downText = situation?.downDistanceText
        var lastPlayText: String? = summary.plays?.last?.text

        let drives = (summary.drives?.previous ?? []).map { d in
            GameDrive(uniqueID: d.id ?? UUID().uuidString,
                      teamID: d.team?.id ?? "",
                      teamAbbr: d.team?.abbreviation ?? "",
                      description: d.description ?? "")
        }

        // Plays: newest-first when a flat play-by-play exists; otherwise fall
        // back to drive summaries so the UI still has something chronological.
        var plays = [GamePlay]()
        if let rawPlays = summary.plays, !rawPlays.isEmpty {
            plays = rawPlays.enumerated().map { index, p in
                let teamID = p.team?.id ?? p.start?.team?.id
                let teamAbbr = p.team?.abbreviation ?? p.start?.team?.abbreviation
                if possessionID == nil, let id = teamID { possessionID = id }
                if downText == nil, let t = p.start?.downDistanceText { downText = t }
                if lastPlayText == nil, let t = p.text, !t.isEmpty { lastPlayText = t }
                return GamePlay(uniqueID: p.id ?? "play-\(index)",
                                quarter: p.period?.number ?? 0,
                                clock: p.clock?.displayValue ?? "",
                                teamID: teamID,
                                teamAbbr: teamAbbr,
                                isScoring: p.scoringPlay ?? false,
                                downText: p.start?.downDistanceText,
                                text: p.text ?? "")
            }
            if plays.count > 80 { plays = Array(plays.suffix(80)) }
            plays.reverse()
        } else if !drives.isEmpty {
            plays = drives.reversed().map { d in
                GamePlay(uniqueID: d.uniqueID + "-drive",
                         quarter: 0,
                         clock: "",
                         teamID: d.teamID,
                         teamAbbr: d.teamAbbr,
                         isScoring: false,
                         downText: nil,
                         text: d.description)
            }
        }

        let scoringPlays = (summary.scoringPlays ?? []).enumerated().map { index, s in
            GameScoringPlay(uniqueID: s.id ?? "scoring-\(index)",
                            quarter: s.period?.number ?? 0,
                            clock: s.clock?.displayValue ?? "",
                            teamID: s.team?.id ?? "",
                            teamAbbr: s.team?.abbreviation ?? "",
                            title: s.type?.text ?? "Score",
                            detail: s.text ?? "",
                            awayScore: Int(s.awayScore ?? "") ?? 0,
                            homeScore: Int(s.homeScore ?? "") ?? 0)
        }

        // Box score team stats.
        var awayStats = [GameStat]()
        var homeStats = [GameStat]()
        for teamBox in summary.boxscore?.teams ?? [] {
            let stats = (teamBox.statistics ?? []).compactMap { s -> GameStat? in
                guard let label = s.label, let value = s.displayValue, !label.isEmpty else { return nil }
                return GameStat(label: label, value: value, isKey: isKeyStat(name: s.name))
            }
            if teamBox.homeAway == "home" {
                homeStats = stats
            } else {
                awayStats = stats
            }
        }

        // Player stat groups (passing/rushing/receiving/...).
        var playerGroups = [PlayerStatGroup]()
        for playerBox in summary.boxscore?.players ?? [] {
            let team = playerBox.team
            for group in playerBox.statistics ?? [] {
                let rows = (group.athletes ?? []).map { line in
                    let athlete = line.athlete
                    return PlayerStatRow(name: athlete?.displayName ?? "—",
                                         position: athlete?.position?.abbreviation,
                                         jersey: athlete?.jersey ?? "",
                                         stats: line.stats ?? [],
                                         headshotURL: athlete?.headshot?.href)
                }
                guard !rows.isEmpty else { continue }
                playerGroups.append(PlayerStatGroup(teamID: team?.id ?? "",
                                                    teamAbbr: team?.abbreviation ?? "",
                                                    name: group.name ?? group.text ?? "stats",
                                                    labels: group.labels ?? [],
                                                    rows: rows))
            }
        }

        // Rosters (available for in-season games).
        var awayRoster = [RosterEntry]()
        var homeRoster = [RosterEntry]()
        for teamRoster in summary.rosters ?? [] {
            let isHome = teamRoster.team?.id == home.teamID
            let entries = (teamRoster.roster ?? []).compactMap { entry -> RosterEntry? in
                guard let athlete = entry.athlete, let name = athlete.displayName, !name.isEmpty else { return nil }
                return RosterEntry(athleteID: athlete.id,
                                   name: name,
                                   position: athlete.position?.abbreviation ?? entry.position ?? "",
                                   jersey: athlete.jersey ?? "",
                                   isStarter: athlete.starter ?? false,
                                   headshotURL: athlete.headshot?.href)
            }
            if isHome { homeRoster = entries } else { awayRoster = entries }
        }

        let gameInfo = summary.gameInfo
        let weatherText: String? = {
            guard let weather = gameInfo?.weather else { return nil }
            var parts = [String]()
            if let t = weather.temperature { parts.append("\(t)°") }
            if let v = weather.displayValue, !v.isEmpty { parts.append(v) }
            if let w = weather.wind?.displayValue, !w.isEmpty { parts.append("wind \(w)") }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }()

        let oddsLine: String? = {
            guard let odds = summary.odds?.first else { return nil }
            if let details = odds.details, !details.isEmpty { return details }
            var parts = [String]()
            if let spread = odds.spread {
                let fav = (odds.awayTeamOdds?.favorite == true) ? away.abbreviation : home.abbreviation
                let sign = spread > 0 ? "+" : ""
                parts.append("\(fav) \(sign)\(Int(spread))")
            }
            if let ou = odds.overUnder { parts.append("O/U \(Int(ou))") }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }()

        let broadcast = (summary.broadcasts?.first?.names ?? competition?.broadcasts?.first?.names)?.joined(separator: ", ")
        let compDate = competition?.date

        let period = competition?.status?.period
        let displayClock = competition?.status?.displayClock

        var statusDetail = status?.detail ?? "Final"
        if rawState == .final, !statusDetail.lowercased().hasPrefix("final") {
            statusDetail = "Final \(statusDetail)"   // e.g. "Final OT"
        }

        return BillsGame(
            eventID: eventID,
            kickoff: date(from: compDate),
            state: rawState,
            statusDetail: statusDetail,
            quarter: period,
            clock: displayClock,
            away: away,
            home: home,
            possessionTeamID: possessionID,
            downDistanceText: downText,
            lastPlayText: lastPlayText,
            venueName: gameInfo?.venue?.fullName ?? competition?.venue?.fullName,
            venueCity: gameInfo?.venue?.address?.city ?? competition?.venue?.address?.city,
            broadcast: broadcast,
            oddsLine: oddsLine,
            weatherText: weatherText,
            scoringPlays: scoringPlays,
            plays: plays,
            drives: drives,
            awayStats: awayStats,
            homeStats: homeStats,
            playerGroups: playerGroups,
            awayRoster: awayRoster,
            homeRoster: homeRoster,
            fetchedAt: Date()
        )
    }

    private static func isKeyStat(name: String?) -> Bool {
        guard let name = name else { return false }
        let keys = ["totalYards", "rushingYards", "passingYards", "turnovers",
                    "firstDowns", "thirdDownEfficiency", "possessionTime", "sacks",
                    "penaltyYards", "netPassingYards", "completionAttempts"]
        return keys.contains(name)
    }
}
