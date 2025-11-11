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
    /// FR-015, FR-016, FR-017: Intelligent ranking, filter variants, deduplicate
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

    /// Filter and rank results with intelligent algorithm (FR-015, FR-016, FR-017)
    @MainActor
    private func filterResults(query: String) {
        let lowercasedQuery = query.lowercased()

        // Filter coins matching query
        let matches = allCoins.filter { coin in
            coin.name.lowercased().contains(lowercasedQuery) ||
            coin.symbol.lowercased().contains(lowercasedQuery) ||
            coin.id.lowercased().contains(lowercasedQuery)
        }

        // FR-016: Filter out exchange-specific variants (coins with parentheses)
        let filteredMatches = matches.filter { coin in
            !coin.name.contains("(") && !coin.name.contains(")")
        }

        // FR-017: Deduplicate by coin ID
        let deduplicated = deduplicateResults(filteredMatches)

        // FR-015: Intelligent ranking - prioritize exact matches and "starts with"
        let ranked = deduplicated.sorted { coin1, coin2 in
            let name1 = coin1.name.lowercased()
            let symbol1 = coin1.symbol.lowercased()
            let name2 = coin2.name.lowercased()
            let symbol2 = coin2.symbol.lowercased()

            // Priority 1: Exact matches (highest priority)
            let isExact1 = name1 == lowercasedQuery || symbol1 == lowercasedQuery
            let isExact2 = name2 == lowercasedQuery || symbol2 == lowercasedQuery
            if isExact1 != isExact2 {
                return isExact1
            }

            // Priority 2: Starts with query
            let startsWith1 = name1.hasPrefix(lowercasedQuery) || symbol1.hasPrefix(lowercasedQuery)
            let startsWith2 = name2.hasPrefix(lowercasedQuery) || symbol2.hasPrefix(lowercasedQuery)
            if startsWith1 != startsWith2 {
                return startsWith1
            }

            // Priority 3: Alphabetical by name
            return name1 < name2
        }

        // Limit to top 50 results
        searchResults = Array(ranked.prefix(50))

        Logger.logic.debug("CoinSearchViewModel: Found \(self.searchResults.count) results for '\(query)'")
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
