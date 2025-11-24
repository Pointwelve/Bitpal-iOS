//
//  CoinSearchView.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI
import OSLog

/// Search sheet for finding and adding cryptocurrencies
/// Per Constitution Principle III: Stateless view (business logic in ViewModel)
struct CoinSearchView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Bindings

    @Binding var watchlistViewModel: WatchlistViewModel

    // MARK: - State

    @State private var viewModel = CoinSearchViewModel()
    @State private var showDuplicateAlert = false
    @State private var selectedCoin: CoinListItem?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                searchField

                // Results list
                if viewModel.isLoading {
                    LoadingView(message: "Loading cryptocurrencies...")
                        .frame(maxHeight: .infinity)
                } else if viewModel.searchQuery.isEmpty {
                    emptySearchState
                } else if viewModel.searchResults.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }
            }
            .navigationTitle("Add Cryptocurrency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadCoinList()
            }
            .alert("Already in Watchlist", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let coin = selectedCoin {
                    Text("\(coin.name) is already in your watchlist")
                }
            }
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
                ForEach(viewModel.searchResults) { coin in
                    Button {
                        addCoinToWatchlist(coin)
                    } label: {
                        SearchResultRow(coin: coin)
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

    // MARK: - Actions

    private func addCoinToWatchlist(_ coin: CoinListItem) {
        selectedCoin = coin

        do {
            try watchlistViewModel.addCoin(coinId: coin.id)
            Logger.ui.info("CoinSearchView: Added \(coin.name) to watchlist")

            // Dismiss sheet after successful addition
            dismiss()
        } catch WatchlistError.coinAlreadyExists {
            Logger.ui.warning("CoinSearchView: \(coin.name) already in watchlist")
            showDuplicateAlert = true
        } catch {
            Logger.error.error("CoinSearchView: Failed to add coin: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    CoinSearchView(watchlistViewModel: .constant(WatchlistViewModel()))
}
