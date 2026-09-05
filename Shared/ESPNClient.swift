//
//  ESPNClient.swift
//  Shared
//
//  Thin async client for ESPN's public, unofficial NFL endpoints.
//
//  Two hosts are used because ESPN blocks some networks on one host but not
//  the other; the client transparently falls back. The canonical host works
//  from residential IPs (which is where an iPhone/iPad runs).
//
//  Endpoints used:
//    GET /apis/site/v2/sports/football/nfl/scoreboard           (current week)
//    GET /apis/site/v2/sports/football/nfl/teams/buf/schedule   (full season)
//    GET /apis/site/v2/sports/football/nfl/summary?event=<id>   (rich game)
//

import Foundation

public struct ESPNClient {
    public static let shared = ESPNClient()

    private static let primaryHost = "https://site.api.espn.com"
    private static let fallbackHost = "https://site.web.api.espn.com"
    private static let path = "/apis/site/v2/sports/football/nfl"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private var baseURL: String { Self.primaryHost + Self.path }

    // MARK: - HTTP

    private func getJSON<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        var components = URLComponents(string: baseURL + path)!
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw ESPNError.badURL }

        let (data, response) = try await fetchWithFallback(url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ESPNError.http((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    /// Retries once against the secondary host when the first host refuses
    /// (403) or fails to connect.
    private func fetchWithFallback(_ url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch {
            guard url.absoluteString.hasPrefix(Self.primaryHost),
                  let alt = URL(string: url.absoluteString.replacingOccurrences(of: Self.primaryHost, with: Self.fallbackHost)) else {
                throw error
            }
            return try await session.data(from: alt)
        }
    }

    // MARK: - Endpoints

    public func scoreboard() async throws -> ScoreboardResponse {
        try await getJSON("/scoreboard")
    }

    public func schedule(season: Int) async throws -> ScheduleResponse {
        try await getJSON("/teams/buf/schedule", query: [URLQueryItem(name: "season", value: "\(season)")])
    }

    public func summary(eventID: String) async throws -> GameSummary {
        try await getJSON("/summary", query: [URLQueryItem(name: "event", value: eventID)])
    }

    // MARK: - "The Bills game" resolver

    /// Current season for a given date (Jan/Feb belong to the previous season).
    public static func seasonYear(for date: Date = Date()) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        return month <= 2 ? year - 1 : year
    }

    /// Finds the Bills game worth showing: the live one if any, else the next
    /// scheduled one, else the most recent finished one.
    /// Throws `ESPNError.noGame` when there is genuinely nothing to show.
    public func fetchBillsGame() async throws -> BillsGame {
        // 1. The current-week scoreboard is the cheapest live/scheduled source.
        let now = Date()
        let board = try await scoreboard()
        if let event = findBillsEvent(in: board.events), let id = event.id, !id.isEmpty {
            let state = event.competitions?.first?.status?.type?.state ?? "post"
            let kickoff = BillsGame.date(from: event.date) ?? now
            // Prefer live/pre games; keep a final only while it's fresh.
            // Otherwise fall through so a closer upcoming game wins.
            if state == "in" || state == "pre" || now.timeIntervalSince(kickoff) < 26 * 3600 {
                let summary = try await summary(eventID: id)
                return BillsGame.build(from: summary, eventID: id)
            }
        }

        // 2. Otherwise consult the full-season schedule.
        let season = Self.seasonYear()
        let sched = try await schedule(season: season)
        let events = sched.events ?? []

        let upcoming = events
            .filter { ($0.competitions?.first?.status?.type?.state ?? "post") == "pre" && $0.kickoffDate > now.addingTimeInterval(-2 * 3600) }
            .sorted { $0.kickoffDate < $1.kickoffDate }
            .first

        let target = upcoming
            ?? events.filter { $0.competitions?.first?.status?.type?.state != "pre" }
                .sorted { $0.kickoffDate > $1.kickoffDate }
                .first

        guard let target = target, let id = target.id else { throw ESPNError.noGame }

        let summary = try await summary(eventID: id)
        return BillsGame.build(from: summary, eventID: id)
    }
}

// MARK: - Resolver helpers

public extension ESPNClient {
    /// Lightweight event container used by full-season schedule discovery.
    struct ScheduleResponse: Decodable {
        public let events: [EventStub]?
    }

    struct EventStub: Decodable {
        public let id: String?
        public let uid: String?
        public let date: String?
        public let shortName: String?
        public let competitions: [Competition]?

        public var kickoffDate: Date {
            BillsGame.date(from: date) ?? .distantPast
        }

        public var state: String? {
            competitions?.first?.status?.type?.state
        }
    }

    private func findBillsEvent(in events: [ScoreboardEvent]?) -> ScoreboardEvent? {
        (events ?? []).first { event in
            event.competitions?.first?.competitors?.contains { $0.team?.id == BillsGame.billsTeamID } == true
        }
    }
}

public enum ESPNError: LocalizedError {
    case badURL
    case http(Int)
    case noGame
    case decoding(Error)

    public var errorDescription: String? {
        switch self {
        case .badURL: return "Could not build the request URL."
        case .http(let code): return "The stats server responded with error \(code)."
        case .noGame: return "No Bills game found right now."
        case .decoding(let error): return "Could not read the stats response: \(error.localizedDescription)"
        }
    }
}
