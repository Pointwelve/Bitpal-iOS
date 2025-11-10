//
//  CoinSearchViewModel.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation
import Observation
import OSLog

/// ViewModel for cryptocurrency search functionality
/// Per Constitution Principle III: Use @Observable (NOT ObservableObject)
@Observable
final class CoinSearchViewModel {
    // MARK: - State

    /// Current search query
    var searchQuery: String = ""

    /// Filtered search results
    var searchResults: [CoinListItem] = []

    /// Loading state
    var isLoading = false

    /// Error message
    var errorMessage: String?

    // MARK: - Dependencies

    private let coinGeckoService: CoinGeckoService
    private var allCoins: [CoinListItem] = []
    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(coinGeckoService: CoinGeckoService = .shared) {
        self.coinGeckoService = coinGeckoService
    }

    // MARK: - Actions

    /// Load coin list from API (cached for 7 days)
    @MainActor
    func loadCoinList() async {
        isLoading = true
        errorMessage = nil

        do {
            allCoins = try await coinGeckoService.fetchCoinList()
            Logger.logic.info("CoinSearchViewModel: Loaded \(self.allCoins.count) coins for search")
            isLoading = false
        } catch {
            Logger.error.error("CoinSearchViewModel: Failed to load coin list: \(error.localizedDescription)")
            errorMessage = "Failed to load cryptocurrencies"
            isLoading = false
        }
    }

    /// Perform search with debounce (300ms)
    /// Per Constitution Principle I: Efficient local search with cached data
    @MainActor
    func performSearch() {
        // Cancel previous search task
        searchTask?.cancel()

        // Empty query - clear results
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        // Debounce search (300ms)
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            await filterResults(query: searchQuery)
        }
    }

    /// Filter results based on search query (case-insensitive)
    @MainActor
    private func filterResults(query: String) {
        let lowercasedQuery = query.lowercased()

        searchResults = allCoins.filter { coin in
            coin.name.lowercased().contains(lowercasedQuery) ||
            coin.symbol.lowercased().contains(lowercasedQuery) ||
            coin.id.lowercased().contains(lowercasedQuery)
        }

        Logger.logic.debug("CoinSearchViewModel: Found \(self.searchResults.count) results for '\(query)'")
    }
}
