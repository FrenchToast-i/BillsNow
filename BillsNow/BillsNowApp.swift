//
//  BillsNowApp.swift
//  BillsNow
//

import SwiftUI

@main
struct BillsNowApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    // Deep links from the widget land here. The Game tab is
                    // already first, so nothing else needs to happen.
                    _ = url
                }
        }
    }
}
