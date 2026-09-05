//
//  RootView.swift
//  BillsNow
//

import SwiftUI

struct RootView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                GameView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("Game", systemImage: "football.fill")
            }
            .tag(0)

            NavigationView {
                NewsView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Label("News", systemImage: "newspaper.fill")
            }
            .tag(1)
        }
        .accentColor(BillsBrand.billsBlue)
    }
}
