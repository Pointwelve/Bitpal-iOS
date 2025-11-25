//
//  ContentView.swift
//  Bitpal
//
//  Created by James Lai on 8/11/25.
//

import SwiftUI

/// Main app content view with tab navigation
/// Per Constitution Principle V: Phase 1 scope includes Watchlist and Manual Portfolio
struct ContentView: View {
    var body: some View {
        TabView {
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }

            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
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
