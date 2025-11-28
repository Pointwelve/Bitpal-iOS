//
//  Logger.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import OSLog

/// Categorized logging for Bitpal app
/// Per Constitution: Use OSLog for structured logging with performance-optimized categories
extension Logger {
    /// Subsystem identifier for all Bitpal logs
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.bitpal.app"

    // MARK: - Log Categories

    /// API-related logs (CoinGecko service, network requests, rate limiting)
    static let api = Logger(subsystem: subsystem, category: "api")

    /// Persistence logs (Swift Data operations, model changes, caching)
    static let persistence = Logger(subsystem: subsystem, category: "persistence")

    /// UI logs (view lifecycle, user interactions, performance metrics)
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Business logic logs (calculations, data transformations, validations)
    static let logic = Logger(subsystem: subsystem, category: "logic")

    /// Error logs (exceptions, failures, error recovery)
    static let error = Logger(subsystem: subsystem, category: "error")

    /// Widget logs (timeline provider, data sync, widget lifecycle)
    static let widget = Logger(subsystem: subsystem, category: "widget")
}

// MARK: - Usage Examples
/*

 // API logging
 Logger.api.info("Fetching market data for \(coinIds.count) coins")
 Logger.api.error("API request failed: \(error.localizedDescription)")

 // Persistence logging
 Logger.persistence.debug("Saving WatchlistItem with coinId: \(coinId)")
 Logger.persistence.warning("Duplicate coin detected: \(coinId)")

 // UI logging
 Logger.ui.trace("WatchlistView appeared")
 Logger.ui.notice("Price update triggered by pull-to-refresh")

 // Logic logging
 Logger.logic.info("Sorting watchlist by price (high to low)")
 Logger.logic.debug("Computed sortedWatchlist with \(count) items")

 // Error logging
 Logger.error.critical("Failed to initialize Swift Data model container")
 Logger.error.fault("Unrecoverable error in price update service")

 */
