//
//  WatchlistViewModel.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation
import SwiftData
import Observation
import OSLog

/// ViewModel for Watchlist feature
/// Per Constitution Principle III: Use @Observable (NOT ObservableObject)
@Observable
final class WatchlistViewModel {
    // MARK: - State

    /// Combined watchlist data (WatchlistItem + Coin)
    var watchlistCoins: [(WatchlistItem, Coin)] = []

    /// UI loading state
    var isLoading = false

    /// Error message to display
    var errorMessage: String?

    /// Timestamp of last successful price update
    var lastUpdateTime: Date?

    /// Current sort option (default: Market Cap per user request)
    var sortOption: SortOption = .marketCap

    // MARK: - Computed Properties

    /// Sorted watchlist based on current sortOption
    var sortedWatchlist: [(WatchlistItem, Coin)] {
        switch sortOption {
        case .marketCap:
            return watchlistCoins.sorted { ($0.1.marketCap ?? 0) > ($1.1.marketCap ?? 0) }
        case .name:
            return watchlistCoins.sorted { $0.1.name < $1.1.name }
        case .price:
            return watchlistCoins.sorted { $0.1.currentPrice > $1.1.currentPrice }
        case .change24h:
            return watchlistCoins.sorted { $0.1.priceChange24h > $1.1.priceChange24h }
        }
    }

    // MARK: - Dependencies

    private let coinGeckoService: CoinGeckoService
    private let priceUpdateService: PriceUpdateService
    private var modelContext: ModelContext?

    // MARK: - Initialization

    init(
        coinGeckoService: CoinGeckoService = .shared,
        priceUpdateService: PriceUpdateService = .shared
    ) {
        self.coinGeckoService = coinGeckoService
        self.priceUpdateService = priceUpdateService
    }

    // MARK: - Configuration

    /// Configure with SwiftData model context
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Actions

    /// Load watchlist items and fetch current prices
    /// Called on view appear
    @MainActor
    func loadWatchlistWithPrices() async {
        guard let context = modelContext else {
            Logger.logic.error("WatchlistViewModel: modelContext not configured")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Fetch WatchlistItems from Swift Data
            let descriptor = FetchDescriptor<WatchlistItem>(
                sortBy: [SortDescriptor(\.dateAdded, order: .forward)]
            )
            let watchlistItems = try context.fetch(descriptor)

            Logger.persistence.info("WatchlistViewModel: Loaded \(watchlistItems.count) items from Swift Data")

            guard !watchlistItems.isEmpty else {
                // Empty watchlist - no API call needed
                watchlistCoins = []
                isLoading = false
                return
            }

            // Fetch prices from API (batched request per Constitution)
            let coinIds = watchlistItems.map { $0.coinId }
            let prices = try await coinGeckoService.fetchMarketData(coinIds: coinIds)

            // Join WatchlistItem with Coin data
            watchlistCoins = watchlistItems.compactMap { item in
                guard let coin = prices[item.coinId] else {
                    Logger.logic.warning("WatchlistViewModel: No price data for \(item.coinId)")
                    return nil
                }
                return (item, coin)
            }

            lastUpdateTime = Date()
            isLoading = false

            Logger.logic.info("WatchlistViewModel: Loaded \(self.watchlistCoins.count) coins with prices")

            // Start periodic updates
            startPeriodicUpdates()

        } catch {
            Logger.error.error("WatchlistViewModel: Failed to load watchlist: \(error.localizedDescription)")
            errorMessage = "Failed to load prices: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Refresh prices (pull-to-refresh)
    @MainActor
    func refreshPrices() async {
        guard let context = modelContext else { return }
        guard !watchlistCoins.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Get current coin IDs
            let coinIds = watchlistCoins.map { $0.0.coinId }

            // Force fresh fetch from API
            let prices = try await priceUpdateService.refreshPrices(for: coinIds)

            // Update coin data while preserving WatchlistItem order
            watchlistCoins = watchlistCoins.compactMap { (item, oldCoin) in
                if let newCoin = prices[item.coinId] {
                    return (item, newCoin)
                } else {
                    return (item, oldCoin) // Keep old data if fetch failed
                }
            }

            lastUpdateTime = Date()
            isLoading = false

            Logger.logic.info("WatchlistViewModel: Refreshed prices for \(self.watchlistCoins.count) coins")

        } catch {
            Logger.error.error("WatchlistViewModel: Refresh failed: \(error.localizedDescription)")
            errorMessage = "Failed to refresh: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Start periodic price updates (30-second interval per Constitution)
    private func startPeriodicUpdates() {
        let coinIds = watchlistCoins.map { $0.0.coinId }

        priceUpdateService.onPricesUpdated = { [weak self] prices in
            guard let self = self else { return }

            // Update coin data
            self.watchlistCoins = self.watchlistCoins.compactMap { (item, oldCoin) in
                if let newCoin = prices[item.coinId] {
                    return (item, newCoin)
                } else {
                    return (item, oldCoin)
                }
            }

            self.lastUpdateTime = Date()

            Logger.logic.debug("WatchlistViewModel: Auto-updated prices")
        }

        priceUpdateService.startPeriodicUpdates(for: coinIds)
    }

    /// Stop periodic updates (called on view disappear)
    func stopPeriodicUpdates() {
        priceUpdateService.stopPeriodicUpdates()
        Logger.logic.info("WatchlistViewModel: Stopped periodic updates")
    }

    /// Add coin to watchlist
    @MainActor
    func addCoin(coinId: String) throws {
        guard let context = modelContext else {
            throw WatchlistError.saveFailed(NSError(domain: "No model context", code: -1))
        }

        // Check for duplicates
        let existing = watchlistCoins.contains { $0.0.coinId == coinId }
        if existing {
            throw WatchlistError.coinAlreadyExists
        }

        // Create and insert WatchlistItem
        let item = WatchlistItem(coinId: coinId)
        context.insert(item)

        do {
            try context.save()
            Logger.persistence.info("WatchlistViewModel: Added \(coinId) to watchlist")

            // Reload to fetch price data
            Task {
                await loadWatchlistWithPrices()
            }
        } catch {
            throw WatchlistError.saveFailed(error)
        }
    }

    /// Remove coin from watchlist
    @MainActor
    func removeCoin(coinId: String) {
        guard let context = modelContext else { return }

        // Find and delete WatchlistItem
        if let index = watchlistCoins.firstIndex(where: { $0.0.coinId == coinId }) {
            let item = watchlistCoins[index].0
            context.delete(item)

            do {
                try context.save()
                watchlistCoins.remove(at: index)
                Logger.persistence.info("WatchlistViewModel: Removed \(coinId) from watchlist")

                // Restart updates with new coin list
                if !watchlistCoins.isEmpty {
                    startPeriodicUpdates()
                } else {
                    stopPeriodicUpdates()
                }
            } catch {
                Logger.error.error("WatchlistViewModel: Failed to remove coin: \(error.localizedDescription)")
            }
        }
    }
}
