//
//  CoinPickerView.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import SwiftUI
import OSLog

/// Coin picker for transaction entry
/// Per FR-029: Shows owned coins first for sell transactions
struct CoinPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = CoinSearchViewModel()

    /// Coins the user already owns (shown first for sell)
    let ownedCoinIds: [String]

    /// Callback when a coin is selected
    let onSelect: (CoinListItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            searchField

            // Results list
            if viewModel.isLoading {
                LoadingView(message: "Loading cryptocurrencies...")
                    .frame(maxHeight: .infinity)
            } else if viewModel.searchQuery.isEmpty {
                // T065: Show owned coins directly without search (FR-031)
                if !ownedCoinIds.isEmpty {
                    ownedCoinsState
                } else {
                    emptySearchState
                }
            } else if viewModel.searchResults.isEmpty {
                noResultsState
            } else {
                resultsList
            }
        }
        .task {
            await viewModel.loadCoinList()
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)

            TextField("Search cryptocurrencies...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: viewModel.searchQuery) {
                    viewModel.performSearch()
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .cornerRadius(Spacing.small)
        .padding(Spacing.medium)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.small) {
                // Sort results: owned coins first (FR-029)
                ForEach(sortedResults) { coin in
                    Button {
                        onSelect(coin)
                    } label: {
                        CoinPickerRow(
                            coin: coin,
                            isOwned: ownedCoinIds.contains(coin.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)

            Text("Search for cryptocurrencies")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            Text("Type a name or symbol to get started")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
        }
        .frame(maxHeight: .infinity)
        .padding(Spacing.xlarge)
    }

    /// T065: Show owned coins directly without search (FR-031)
    private var ownedCoinsState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Section header
                Text("Your Coins")
                    .font(Typography.headline)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.small)

                // Owned coins list
                LazyVStack(spacing: Spacing.small) {
                    ForEach(ownedCoins) { coin in
                        Button {
                            onSelect(coin)
                        } label: {
                            CoinPickerRow(coin: coin, isOwned: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.medium)

                // Search prompt
                VStack(spacing: Spacing.small) {
                    Divider()
                        .padding(.vertical, Spacing.medium)

                    Text("Search for more coins above")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, Spacing.medium)
            }
        }
    }

    /// Get owned coins from the coin list
    private var ownedCoins: [CoinListItem] {
        viewModel.coinList.filter { ownedCoinIds.contains($0.id) }
    }

    private var noResultsState: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)

            Text("No results found")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            Text("Try searching for a different cryptocurrency")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
        }
        .frame(maxHeight: .infinity)
        .padding(Spacing.xlarge)
    }

    // MARK: - Helpers

    /// Sort results with owned coins first per FR-029
    private var sortedResults: [CoinListItem] {
        viewModel.searchResults.sorted { coin1, coin2 in
            let owned1 = ownedCoinIds.contains(coin1.id)
            let owned2 = ownedCoinIds.contains(coin2.id)

            if owned1 && !owned2 {
                return true
            } else if !owned1 && owned2 {
                return false
            } else {
                return false // Maintain original order for same category
            }
        }
    }
}

// MARK: - Coin Picker Row

/// Row display for coin picker with ownership indicator
struct CoinPickerRow: View {
    let coin: CoinListItem
    let isOwned: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                HStack(spacing: Spacing.small) {
                    Text(coin.name)
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    if isOwned {
                        Text("Owned")
                            .font(Typography.caption)
                            .foregroundColor(.profitGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.profitGreen.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text(coin.symbol.uppercased())
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .cornerRadius(Spacing.small)
    }
}

#Preview {
    CoinPickerView(ownedCoinIds: ["bitcoin", "ethereum"]) { coin in
        print("Selected: \(coin.name)")
    }
}
