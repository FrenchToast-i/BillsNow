//
//  BillsModels.swift
//  Shared
//
//  Wire models that mirror the JSON produced by ESPN's public (unofficial)
//  scoreboard / summary endpoints. Every property is decoded defensively
//  (optionals / decodeIfPresent) so a field ESPN adds or renames never
//  crashes the app.
//
//  Decoding uses `.convertFromSnakeCase`, so property names are camelCase
//  versions of the JSON keys.
//

import Foundation

// MARK: - Scoreboard (lightweight, used by the widget and game discovery)

public struct ScoreboardResponse: Decodable {
    public let events: [ScoreboardEvent]?
}

public struct ScoreboardEvent: Decodable {
    public let id: String?
    public let date: String?
    public let name: String?
    public let shortName: String?
    public let competitions: [Competition]?
}

// MARK: - Shared blocks

public struct Competition: Decodable {
    public let id: String?
    public let date: String?
    public let status: StatusBlock?
    public let competitors: [Competitor]?
    public let situation: Situation?
    public let broadcasts: [Broadcast]?
    public let venue: Venue?
    public let odds: [Odds]?
    public let details: [DetailItem]?
}

public struct StatusBlock: Decodable {
    public let clock: Double?
    public let displayClock: String?
    public let period: Int?
    public let type: StatusType?
}

public struct StatusType: Decodable {
    public let id: String?
    public let name: String?
    public let state: String?        // "pre" | "in" | "post"
    public let detail: String?       // "Q2 8:12", "Final", ...
    public let shortDetail: String?
    public let description: String?
    public let completed: Bool?
}

public struct Competitor: Decodable {
    public let id: String?
    public let homeAway: String?     // "home" | "away"
    public let score: String?
    public let winner: Bool?
    public let record: [Record]?
    public let team: Team?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decode(String.self, forKey: .id)
        homeAway = try? c.decode(String.self, forKey: .homeAway)
        winner = try? c.decode(Bool.self, forKey: .winner)
        record = try? c.decode([Record].self, forKey: .record)
        team = try? c.decode(Team.self, forKey: .team)
        // The scoreboard sends a plain "29"; the schedule endpoint sends
        // {"value": 29.0, "displayValue": "29"}. Accept both.
        if let plain = try? c.decode(String.self, forKey: .score) {
            score = plain
        } else {
            score = (try? c.decode(ScoreValue.self, forKey: .score))?.displayValue
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, homeAway, score, winner, record, team
    }
}

private struct ScoreValue: Decodable {
    public let displayValue: String?
}

public struct Team: Decodable {
    public let id: String?
    public let abbreviation: String?
    public let displayName: String?
    public let shortDisplayName: String?
    public let name: String?
    public let location: String?
    public let color: String?
    public let alternateColor: String?
    public let logos: [Logo]?
    public let logo: String?
}

public struct Logo: Decodable {
    public let href: String?
    public let rel: [String]?
}

public struct Record: Decodable {
    public let type: String?
    public let summary: String?
    public let displayValue: String?
}

/// Down / distance / possession while a game is live.
public struct Situation: Decodable {
    public let down: Int?
    public let ball: String?                 // team id at line of scrimmage
    public let distance: Int?
    public let yardLine: Int?
    public let possession: String?           // team id with the ball
    public let possessionText: String?
    public let downDistanceText: String?
    public let shortDownDistanceText: String?
    public let isRedZone: Bool?
    public let yardsToEndzone: Int?
}

/// A broadcast entry. ESPN uses two shapes: the scoreboard sends
/// `{ "market": "national", "names": ["NBC"] }` while the summary and
/// schedule endpoints send `{ "market": {"type": "National"}, "media":
/// {"shortName": "CBS"} }`. Decoded defensively so both work.
public struct Broadcast: Decodable {
    public let market: String?
    public let names: [String]?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let plain = try? c.decode(String.self, forKey: .market) {
            market = plain
        } else {
            market = (try? c.decode(BroadcastMarket.self, forKey: .market))?.type
        }
        var decodedNames = try? c.decode([String].self, forKey: .names)
        if decodedNames?.isEmpty != false {
            decodedNames = (try? c.decode(BroadcastMedia.self, forKey: .media))?.shortName.map { [$0] }
        }
        names = decodedNames
    }

    private enum CodingKeys: String, CodingKey {
        case market, names, media
    }
}

private struct BroadcastMarket: Decodable {
    public let type: String?
}

private struct BroadcastMedia: Decodable {
    public let shortName: String?
}

public struct Venue: Decodable {
    public let fullName: String?
    public let address: VenueAddress?
}

public struct VenueAddress: Decodable {
    public let city: String?
    public let state: String?
}

public struct Odds: Decodable {
    public let details: String?              // e.g. "BUF -3.5"
    public let overUnder: Double?
    public let spread: Double?
    public let awayTeamOdds: TeamOdds?
    public let homeTeamOdds: TeamOdds?
}

public struct TeamOdds: Decodable {
    public let favorite: Bool?
    public let moneyLine: Int?
    public let spreadOdds: Double?
    public let team: Team?
}

/// Scoring-play summary entries that occasionally appear on scoreboard comps.
public struct DetailItem: Decodable {
    public let type: TypeBlock?
    public let clock: Clock?
    public let period: PeriodBlock?
    public let team: Team?
    public let text: String?
    public let awayScore: String?
    public let homeScore: String?
}

public struct TypeBlock: Decodable {
    public let id: String?
    public let text: String?
    public let abbreviation: String?
}

public struct Clock: Decodable {
    public let displayValue: String?
}

public struct PeriodBlock: Decodable {
    public let number: Int?
}

// MARK: - Summary (rich, used by the app and cached for offline)

public struct GameSummary: Decodable {
    public let header: HeaderBlock?
    public let plays: [Play]?
    public let scoringPlays: [ScoringPlay]?
    public let drives: DrivesBlock?
    public let boxscore: BoxScore?
    public let rosters: [TeamRoster]?
    public let gameInfo: GameInfo?
    public let odds: [Odds]?
    public let broadcasts: [Broadcast]?
}

public struct HeaderBlock: Decodable {
    public let competitions: [Competition]?
}

/// Full play-by-play line. Only present while a game is live / recently final.
public struct Play: Decodable {
    public let id: String?
    public let type: TypeBlock?
    public let text: String?
    public let awayScore: String?
    public let homeScore: String?
    public let period: PeriodBlock?
    public let clock: Clock?
    public let team: Team?
    public let scoringPlay: Bool?
    public let start: PlayField?
    public let end: PlayField?
    public let drive: DriveReference?
}

public struct PlayField: Decodable {
    public let down: Int?
    public let distance: Int?
    public let yardLine: Int?
    public let team: Team?
    public let possessionText: String?
    public let downDistanceText: String?
    public let shortDownDistanceText: String?
    public let yardsToEndzone: Int?
}

public struct DriveReference: Decodable {
    public let id: String?
    public let description: String?
}

public struct ScoringPlay: Decodable {
    public let id: String?
    public let type: TypeBlock?
    public let text: String?
    public let awayScore: String?
    public let homeScore: String?
    public let period: PeriodBlock?
    public let clock: Clock?
    public let team: Team?
    public let scoringType: ScoringType?
}

public struct ScoringType: Decodable {
    public let id: String?
    public let name: String?
}

public struct DrivesBlock: Decodable {
    public let previous: [Drive]?
    public let current: Drive?
}

public struct Drive: Decodable {
    public let id: String?
    public let description: String?
    public let team: Team?
    public let plays: [Play]?
}

public struct BoxScore: Decodable {
    public let teams: [TeamBoxScore]?
    public let players: [PlayerBox]?
}

public struct TeamBoxScore: Decodable {
    public let team: Team?
    public let homeAway: String?
    public let statistics: [TeamStatistic]?
}

public struct TeamStatistic: Decodable {
    public let name: String?
    public let label: String?
    public let displayValue: String?
}

public struct PlayerBox: Decodable {
    public let team: Team?
    public let statistics: [PlayerStatGroupWire]?
}

/// Wire-level player stat group ("passing", "rushing", ...). Distinct from
/// the domain `PlayerStatGroup` in BillsGame.swift.
public struct PlayerStatGroupWire: Decodable {
    public let name: String?
    public let text: String?
    public let labels: [String]?
    public let athletes: [PlayerStatLine]?
}

public struct PlayerStatLine: Decodable {
    public let athlete: PlayerAthlete?
    public let stats: [String]?
}

public struct PlayerAthlete: Decodable {
    public let id: String?
    public let displayName: String?
    public let shortName: String?
    public let jersey: String?
    public let position: PositionBlock?
    public let headshot: Headshot?
}

public struct PositionBlock: Decodable {
    public let abbreviation: String?
    public let name: String?
}

public struct Headshot: Decodable {
    public let href: String?
}

public struct TeamRoster: Decodable {
    public let team: Team?
    public let roster: [RosterEntryWire]?
}

public struct RosterEntryWire: Decodable {
    public let athlete: RosterAthlete?
    public let position: String?
}

public struct RosterAthlete: Decodable {
    public let id: String?
    public let displayName: String?
    public let shortName: String?
    public let jersey: String?
    public let position: PositionBlock?
    public let headshot: Headshot?
    public let starter: Bool?
}

public struct GameInfo: Decodable {
    public let venue: Venue?
    public let attendance: Int?
    public let weather: GameWeather?
}

public struct GameWeather: Decodable {
    public let temperature: Int?
    public let highTemperature: Int?
    public let lowTemperature: Int?
    public let precipitation: Int?
    public let gust: Int?
    public let wind: Wind?
    public let displayValue: String?
    public let conditionId: String?
}

public struct Wind: Decodable {
    public let displayValue: String?
}
