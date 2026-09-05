//
//  ScoreTimelineProvider.swift
//  BillsWidget
//
//  Fetches "the Bills game right now" for every timeline request. Cadence is
//  state-adaptive: ~30s while live, relaxed before/after. Each fetch starts
//  from the App Group cache so the widget always has something to draw even
//  when the network is slow or unavailable.
//

import WidgetKit

struct ScoreTimelineProvider: TimelineProvider {
    /// Dedicated short-timeout client so a hung request can never blow the
    /// widget's execution budget (also sends the browser-like headers).
    private var client: ESPNClient {
        ESPNClient(session: ESPNClient.makeSession(timeout: 6))
    }

    // MARK: TimelineProvider

    func placeholder(in context: Context) -> ScoreEntry {
        ScoreEntry(date: Date(), game: SampleGame.live)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScoreEntry) -> Void) {
        if context.isPreview {
            // The gallery gets a realistic live snapshot, never a blank card.
            completion(ScoreEntry(date: Date(), game: SampleGame.live))
            return
        }
        Task {
            completion(await makeEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScoreEntry>) -> Void) {
        Task {
            let now = Date()
            var game = SharedCache.load()

            do {
                let fresh = try await client.fetchBillsGame()
                game = fresh
                SharedCache.save(fresh)
            } catch {
                // Keep whatever we cached. If that is nil the view shows the
                // friendly "no game" card.
            }

            let nextReload = Self.nextReload(from: now,
                                             state: game?.state,
                                             kickoff: game?.kickoff)
            let entries = [
                ScoreEntry(date: now, game: game),
                // Stale-but-present fallback: if the next reload's fetch fails,
                // the system still has this entry to show.
                ScoreEntry(date: nextReload, game: game),
            ]
            completion(Timeline(entries: entries, policy: .after(nextReload)))
        }
    }

    // MARK: Helpers

    private func makeEntry() async -> ScoreEntry {
        do {
            let game = try await client.fetchBillsGame()
            SharedCache.save(game)
            return ScoreEntry(date: Date(), game: game)
        } catch {
            return ScoreEntry(date: Date(), game: SharedCache.load())
        }
    }

    /// How long until the widget should ask for a new timeline.
    static func nextReload(from now: Date, state: GameState?, kickoff: Date?) -> Date {
        switch state {
        case .live:
            return now.addingTimeInterval(30)
        case .pre:
            if let kickoff = kickoff {
                return min(now.addingTimeInterval(30 * 60),
                           kickoff.addingTimeInterval(3 * 60))
            }
            return now.addingTimeInterval(30 * 60)
        case .final, .canceled:
            return now.addingTimeInterval(3 * 3600)
        case nil:
            return now.addingTimeInterval(60 * 60)
        }
    }
}
