//
//  SharedCache.swift
//  Shared
//
//  The app and the widget both write and read the latest BillsGame snapshot
//  through the shared App Group container, so the widget can render the last
//  known state immediately (and offline) while its timeline fetch runs.
//

import Foundation

public enum AppGroups {
    /// Must match the App Group in both *.entitlements files and the
    /// signing identity used on the device.
    public static let billsNow = "group.com.billsnow.shared"
}

public enum SharedCache {
    private static let gameKey = "latestBillsGame.v1"
    private static let eventKey = "latestBillsEventID.v1"

    private static var store: UserDefaults? {
        UserDefaults(suiteName: AppGroups.billsNow)
    }

    public static func save(_ game: BillsGame) {
        guard let data = try? JSONEncoder().encode(game) else { return }
        store?.set(data, forKey: gameKey)
        store?.set(game.eventID, forKey: eventKey)
    }

    public static func load() -> BillsGame? {
        guard let data = store?.data(forKey: gameKey) else { return nil }
        return try? JSONDecoder().decode(BillsGame.self, from: data)
    }

    public static func load(eventID: String) -> BillsGame? {
        guard let cached = load(), cached.eventID == eventID else { return nil }
        return cached
    }
}
