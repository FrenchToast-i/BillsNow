//
//  GameViewModel.swift
//  BillsNow
//

import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    @Published var game: BillsGame?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    private let client = ESPNClient.shared
    private let isPreview: Bool

    init(previewGame: BillsGame? = nil) {
        isPreview = previewGame != nil
        game = previewGame
    }

    /// Polls until the surrounding `.task` is torn down. Cadence adapts to
    /// game state: fastest while live, relaxed otherwise.
    func runLoop() async {
        if isPreview { return }

        // Show the last known snapshot immediately if we have one.
        if game == nil {
            game = SharedCache.load()
            if let game = game { lastUpdated = game.fetchedAt }
        }

        while !Task.isCancelled {
            await refresh()
            let interval = refreshInterval()
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }

    private func refreshInterval() -> TimeInterval {
        guard let state = game?.state else {
            return errorMessage == nil ? 30 : 90
        }
        switch state {
        case .live: return 30
        case .pre: return 120
        case .final, .canceled: return 600
        }
    }

    func refresh() async {
        if game == nil { isLoading = true }
        defer { isLoading = false }
        do {
            let fresh = try await client.fetchBillsGame()
            game = fresh
            lastUpdated = fresh.fetchedAt
            errorMessage = nil
            SharedCache.save(fresh)
        } catch {
            // Keep showing whatever we have; surface the error softly with a
            // real description (never the generic "Unknown error").
            if game == nil { game = SharedCache.load() }
            let cast = error as? ESPNError
            if case .noGame? = cast {
                errorMessage = nil
            } else {
                errorMessage = cast?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
