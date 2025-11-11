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
    /// FR-015, FR-016, FR-017: Use CoinGecko markets API with relevance ranking, filter variants, deduplicate
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

            await executeSearch(query: searchQuery)
        }
    }

    /// Execute search using new searchCoins API with relevance ranking and filtering
    @MainActor
    private func executeSearch(query: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Use new searchCoins method (FR-015: relevance ranking, FR-016: filter variants)
            let results = try await coinGeckoService.searchCoins(query: query, limit: 50)

            // FR-017: Deduplicate by coin ID (though searchCoins already handles this)
            searchResults = deduplicateResults(results)

            Logger.logic.info("CoinSearchViewModel: Found \(self.searchResults.count) results for '\(query)'")
            isLoading = false
        } catch {
            Logger.error.error("CoinSearchViewModel: Search failed: \(error.localizedDescription)")
            errorMessage = "Search failed. Please try again."
            searchResults = []
            isLoading = false
        }
    }

    /// Deduplicate search results by coin ID (FR-017)
    private func deduplicateResults(_ results: [CoinListItem]) -> [CoinListItem] {
        var seen = Set<String>()
        return results.filter { coin in
            if seen.contains(coin.id) {
                return false
            }
            seen.insert(coin.id)
            return true
        }
    }
}
