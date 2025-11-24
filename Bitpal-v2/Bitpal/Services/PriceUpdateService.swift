//
//  PriceUpdateService.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation
import OSLog

/// Service for periodic price updates
/// Per Constitution Principle I: 30-second update interval (real-time FORBIDDEN)
final class PriceUpdateService {
    // MARK: - Singleton

    static let shared = PriceUpdateService()

    // MARK: - Properties

    private let updateInterval: TimeInterval = 30 // 30 seconds per Constitution
    private var updateTask: Task<Void, Never>?
    private let coinGeckoService: CoinGeckoService

    /// Callback to notify observers when prices update
    var onPricesUpdated: (([String: Coin]) -> Void)?

    // MARK: - Initialization

    private init(coinGeckoService: CoinGeckoService = .shared) {
        self.coinGeckoService = coinGeckoService
    }

    // MARK: - Public Methods

    /// Start periodic price updates for given coin IDs
    /// Per Constitution: Updates every 30 seconds, NOT real-time
    func startPeriodicUpdates(for coinIds: [String]) {
        // Cancel existing update task if any
        stopPeriodicUpdates()

        guard !coinIds.isEmpty else {
            Logger.api.warning("PriceUpdateService: startPeriodicUpdates called with empty coinIds")
            return
        }

        Logger.api.info("PriceUpdateService: Starting periodic updates for \(coinIds.count) coins (every \(self.updateInterval)s)")

        updateTask = Task {
            while !Task.isCancelled {
                do {
                    // Fetch latest market data
                    let prices = try await coinGeckoService.fetchMarketData(coinIds: coinIds)

                    // Notify observers on main thread
                    await MainActor.run {
                        onPricesUpdated?(prices)
                    }

                    Logger.api.debug("PriceUpdateService: Price update completed, sleeping for \(self.updateInterval)s")

                    // Wait for next update interval
                    try await Task.sleep(for: .seconds(updateInterval))
                } catch is CancellationError {
                    Logger.api.info("PriceUpdateService: Update task cancelled")
                    break
                } catch {
                    Logger.api.error("PriceUpdateService: Price update failed: \(error.localizedDescription)")

                    // Wait before retry to avoid hammering API on errors
                    try? await Task.sleep(for: .seconds(updateInterval))
                }
            }
        }
    }

    /// Stop periodic price updates
    func stopPeriodicUpdates() {
        updateTask?.cancel()
        updateTask = nil
        Logger.api.info("PriceUpdateService: Stopped periodic updates")
    }

    /// Manually trigger a price update (e.g., pull-to-refresh)
    func refreshPrices(for coinIds: [String]) async throws -> [String: Coin] {
        guard !coinIds.isEmpty else {
            Logger.api.warning("PriceUpdateService: refreshPrices called with empty coinIds")
            return [:]
        }

        Logger.api.info("PriceUpdateService: Manual refresh requested for \(coinIds.count) coins")

        // Invalidate cache to force fresh fetch
        coinGeckoService.invalidateMarketDataCache()

        // Fetch latest data
        let prices = try await coinGeckoService.fetchMarketData(coinIds: coinIds)

        Logger.api.info("PriceUpdateService: Manual refresh completed")

        return prices
    }
}
