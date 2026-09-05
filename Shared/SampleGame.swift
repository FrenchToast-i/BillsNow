//
//  SampleGame.swift
//  Shared
//
//  Hand-built BillsGame snapshots used for the widget gallery (getSnapshot)
//  and SwiftUI previews, so the widget never previews a blank card.
//

import Foundation

public enum SampleGame {
    public static var live: BillsGame {
        let billColors = BillsBrand.colors(forAbbreviation: "BUF")
        let oppColors = BillsBrand.colors(forAbbreviation: "KC")
        let kickoff = Calendar(identifier: .gregorian).date(byAdding: .minute, value: -95, to: Date()) ?? Date()
        let bills = TeamSide(teamID: "2", abbreviation: "BUF", shortName: "Bills",
                             displayName: "Buffalo Bills", record: "3-1", score: 24,
                             isWinner: false, isHome: false, colorHex: billColors.primary,
                             accentHex: billColors.secondary,
                             logoURL: "https://a.espncdn.com/i/teamlogos/nfl/500/buf.png")
        let chiefs = TeamSide(teamID: "12", abbreviation: "KC", shortName: "Chiefs",
                              displayName: "Kansas City Chiefs", record: "4-0", score: 20,
                              isWinner: false, isHome: true, colorHex: oppColors.primary,
                              accentHex: oppColors.secondary,
                              logoURL: "https://a.espncdn.com/i/teamlogos/nfl/500/kc.png")
        return BillsGame(
            eventID: "401234567",
            kickoff: kickoff,
            state: .live,
            statusDetail: "Q4 3:12",
            quarter: 4,
            clock: "3:12",
            away: bills,
            home: chiefs,
            possessionTeamID: "2",
            downDistanceText: "3rd & 6 at KC 38",
            lastPlayText: "(3:12 - 3rd down) Josh Allen pass short middle intended for Dalton Kincaid incomplete.",
            venueName: "GEHA Field at Arrowhead Stadium",
            venueCity: "Kansas City",
            broadcast: "CBS",
            oddsLine: nil,
            weatherText: "68° · Partly Cloudy",
            scoringPlays: [
                GameScoringPlay(uniqueID: "s1", quarter: 1, clock: "8:14", teamID: "2", teamAbbr: "BUF",
                                title: "Rushing Touchdown", detail: "James Cook 8 Yd run", awayScore: 7, homeScore: 0),
                GameScoringPlay(uniqueID: "s2", quarter: 1, clock: "2:02", teamID: "12", teamAbbr: "KC",
                                title: "Passing Touchdown", detail: "Patrick Mahomes 3 Yd pass to Travis Kelce", awayScore: 7, homeScore: 7),
                GameScoringPlay(uniqueID: "s3", quarter: 2, clock: "11:45", teamID: "2", teamAbbr: "BUF",
                                title: "Field Goal Good", detail: "Tyler Bass 44 Yd Field Goal", awayScore: 10, homeScore: 7),
                GameScoringPlay(uniqueID: "s4", quarter: 2, clock: "0:03", teamID: "2", teamAbbr: "BUF",
                                title: "Field Goal Good", detail: "Tyler Bass 33 Yd Field Goal", awayScore: 13, homeScore: 7),
                GameScoringPlay(uniqueID: "s5", quarter: 3, clock: "9:31", teamID: "12", teamAbbr: "KC",
                                title: "Passing Touchdown", detail: "Isiah Pacheco 1 Yd run", awayScore: 13, homeScore: 14),
                GameScoringPlay(uniqueID: "s6", quarter: 3, clock: "5:44", teamID: "2", teamAbbr: "BUF",
                                title: "Rushing Touchdown", detail: "Josh Allen 3 Yd run", awayScore: 20, homeScore: 14),
                GameScoringPlay(uniqueID: "s7", quarter: 4, clock: "10:02", teamID: "12", teamAbbr: "KC",
                                title: "Field Goal Good", detail: "Harrison Butker 50 Yd Field Goal", awayScore: 20, homeScore: 17),
                GameScoringPlay(uniqueID: "s8", quarter: 4, clock: "5:11", teamID: "2", teamAbbr: "BUF",
                                title: "Field Goal Good", detail: "Tyler Bass 26 Yd Field Goal", awayScore: 23, homeScore: 17),
                GameScoringPlay(uniqueID: "s9", quarter: 4, clock: "3:12", teamID: "12", teamAbbr: "KC",
                                title: "Field Goal Good", detail: "Harrison Butker 47 Yd Field Goal", awayScore: 23, homeScore: 20),
            ],
            plays: [
                GamePlay(uniqueID: "p1", quarter: 4, clock: "3:12", teamID: "2", teamAbbr: "BUF", isScoring: false, downText: "3rd & 6", text: "J. Allen pass short middle intended for D. Kincaid incomplete."),
                GamePlay(uniqueID: "p2", quarter: 4, clock: "3:22", teamID: "2", teamAbbr: "BUF", isScoring: false, downText: "2nd & 6", text: "J. Allen pass short left to K. Shakir pushed out of bounds for 2 yards."),
                GamePlay(uniqueID: "p3", quarter: 4, clock: "3:38", teamID: "2", teamAbbr: "BUF", isScoring: false, downText: "1st & 10", text: "J. Cook right guard to KC 40 for 5 yards."),
            ],
            drives: [],
            awayStats: [],
            homeStats: [],
            playerGroups: [],
            awayRoster: [],
            homeRoster: [],
            fetchedAt: Date()
        )
    }

    public static var upcoming: BillsGame {
        var game = live
        return BillsGame(
            eventID: game.eventID,
            kickoff: Calendar(identifier: .gregorian).date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            state: .pre,
            statusDetail: "Sun, September 13th at 1:00 PM EDT",
            quarter: nil,
            clock: nil,
            away: game.away,
            home: game.home,
            possessionTeamID: nil,
            downDistanceText: nil,
            lastPlayText: nil,
            venueName: game.venueName,
            venueCity: game.venueCity,
            broadcast: game.broadcast,
            oddsLine: "BUF -2.5 · O/U 48",
            weatherText: nil,
            scoringPlays: [],
            plays: [],
            drives: [],
            awayStats: [],
            homeStats: [],
            playerGroups: [],
            awayRoster: [],
            homeRoster: [],
            fetchedAt: Date()
        )
    }
}
