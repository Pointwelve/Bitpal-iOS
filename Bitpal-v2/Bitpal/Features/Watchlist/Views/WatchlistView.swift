//
//  WatchlistView.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI
import SwiftData

/// Watchlist view displaying user's tracked cryptocurrencies
/// Per Constitution Principle III: Stateless view (business logic in ViewModel)
/// Per Constitution Principle I: LazyVStack for 60fps scrolling performance
struct WatchlistView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel = WatchlistViewModel()
    @State private var showSearchSheet = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.watchlistCoins.isEmpty {
                    // Initial loading state
                    LoadingView(message: "Loading watchlist...")

                } else if viewModel.watchlistCoins.isEmpty {
                    // Empty state
                    emptyStateView

                } else {
                    // Watchlist content
                    ScrollView {
                        LazyVStack(spacing: Spacing.standard) {
                            ForEach(viewModel.sortedWatchlist, id: \.0.coinId) { item, coin in
                                CoinRowView(coin: coin)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewModel.removeCoin(coinId: coin.id)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .opacity,
                                        removal: .opacity.combined(with: .move(edge: .leading))
                                    ))
                            }
                        }
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.sortOption)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.watchlistCoins.count)
                    }
                    .refreshable {
                        await viewModel.refreshPrices()
                    }
                }
            }
            .navigationTitle("Watchlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.watchlistCoins.isEmpty {
                        Menu {
                            Picker("Sort by", selection: $viewModel.sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            HStack(spacing: Spacing.tiny) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Sort")
                            }
                            .font(Typography.caption)
                        }
                    } else if let lastUpdate = viewModel.lastUpdateTime {
                        Text("Updated \(timeAgoString(from: lastUpdate))")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSearchSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .accessibilityLabel("Add cryptocurrency")
                    .accessibilityHint("Opens search to add coins to watchlist")
                }
            }
            .sheet(isPresented: $showSearchSheet) {
                CoinSearchView(watchlistViewModel: $viewModel)
            }
            .overlay(alignment: .top) {
                // Error banner
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
            }
            .task {
                // Configure ViewModel and load data on appear
                viewModel.configure(modelContext: modelContext)
                await viewModel.loadWatchlistWithPrices()
            }
            .onDisappear {
                // Stop periodic updates when view disappears (Constitution-compliant resource management)
                viewModel.stopPeriodicUpdates()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)

            Text("Your watchlist is empty")
                .font(Typography.title3)
                .foregroundColor(.textPrimary)

            Text("Tap + to add cryptocurrencies")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
        }
        .padding(Spacing.xlarge)
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

            Text(message)
                .font(Typography.caption)
                .foregroundColor(.textPrimary)

            Spacer()

            Button("Dismiss") {
                viewModel.errorMessage = nil
            }
            .font(Typography.caption)
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .cornerRadius(Spacing.small)
        .padding(Spacing.medium)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Helper Methods

    private func timeAgoString(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        if seconds < 60 {
            return "now"
        } else if seconds < 120 {
            return "1m ago"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else {
            return "\(Int(seconds / 3600))h ago"
        }
    }
}

// MARK: - Preview

#Preview {
    WatchlistView()
        .modelContainer(for: [WatchlistItem.self], inMemory: true)
}
