//
//  ContentView.swift
//  Bitpal
//
//  Created by James Lai on 8/11/25.
//

import SwiftUI
import WidgetKit

/// Tab selection enum for deep linking support
/// Per FR-010: Widget taps should open Portfolio tab
enum AppTab: Hashable {
    case watchlist
    case portfolio
}

/// Main app content view with tab navigation
/// Per Constitution Principle V: Phase 1 scope includes Watchlist and Manual Portfolio
struct ContentView: View {
    /// T026: Selected tab state for deep linking
    @State private var selectedTab: AppTab = .watchlist

    /// Scene phase for detecting app background transitions
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }
                .tag(AppTab.watchlist)

            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
                .tag(AppTab.portfolio)
        }
        // T026: Handle deep links from widget
        .onOpenURL { url in
            handleDeepLink(url)
        }
        // Refresh widget when app goes to background
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    /// T026: Handle deep link URLs from widget
    /// Per FR-010: bitpal://portfolio opens Portfolio tab
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "bitpal" else { return }

        switch url.host {
        case "portfolio":
            selectedTab = .portfolio
        case "watchlist":
            selectedTab = .watchlist
        default:
            break
        }
    }

    // Placeholder for future Portfolio view
    private func portfolioPlaceholder() -> some View {
        VStack {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)

            Text("Portfolio")
                .font(Typography.title3)

            Text("Coming soon")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    ContentView()
}
