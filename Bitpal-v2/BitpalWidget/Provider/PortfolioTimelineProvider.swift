//
//  PortfolioTimelineProvider.swift
//  BitpalWidget
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//  Updated: 2025-12-11 for 008-widget-background-refresh
//

import WidgetKit
import OSLog

/// Timeline provider for portfolio widgets.
/// Fetches fresh prices from CoinGecko API and recalculates P&L.
/// Per FR-001: Fetches current prices when iOS requests timeline refresh.
/// Per FR-006: Requests refresh every 15 minutes.
struct PortfolioTimelineProvider: TimelineProvider {
    // MARK: - Constants

    /// Refresh interval in minutes (iOS may adjust based on system conditions)
    private static let refreshIntervalMinutes: Double = 15

    // MARK: - Dependencies

    private let storage = AppGroupStorage.shared

    // MARK: - TimelineProvider Protocol

    /// Provides a placeholder entry for the widget gallery.
    /// Per WidgetKit: Should return immediately with sample data.
    func placeholder(in context: Context) -> PortfolioEntry {
        Logger.widget.debug("Generating placeholder entry")
        return .placeholder()
    }

    /// Provides a snapshot entry for widget gallery preview.
    /// Per WidgetKit: Should return quickly with representative data.
    func getSnapshot(in context: Context, completion: @escaping (PortfolioEntry) -> Void) {
        Logger.widget.debug("Generating snapshot entry")

        // Use sample data for gallery preview, real data for home screen
        if context.isPreview {
            completion(.snapshot())
        } else {
            let entry = createEntryFromStorage()
            completion(entry)
        }
    }

    /// Provides timeline entries for the widget.
    /// Per FR-001: Fetches fresh prices from API.
    /// Per FR-004: Falls back to cached data on failure.
    /// Per FR-006: Single entry with 15-minute refresh policy.
    func getTimeline(in context: Context, completion: @escaping (Timeline<PortfolioEntry>) -> Void) {
        Logger.widget.info("Generating timeline - starting fresh price fetch")

        Task {
            let portfolioData: WidgetPortfolioData

            // T009: Read refresh data (quantities for recalculation)
            guard let refreshData = storage.readRefreshData() else {
                // T018 (US3): No refresh data = empty portfolio
                Logger.widget.info("No refresh data available, showing empty state")
                let entry = PortfolioEntry(date: Date(), data: .empty)
                let refreshDate = Date().addingTimeInterval(Self.refreshIntervalMinutes * 60)
                completion(Timeline(entries: [entry], policy: .after(refreshDate)))
                return
            }

            // T018 (US3): Empty holdings
            guard !refreshData.isEmpty else {
                Logger.widget.info("Refresh data has no holdings, showing empty state")
                let entry = PortfolioEntry(date: Date(), data: .empty)
                let refreshDate = Date().addingTimeInterval(Self.refreshIntervalMinutes * 60)
                completion(Timeline(entries: [entry], policy: .after(refreshDate)))
                return
            }

            // T010 (US1): Try to fetch fresh prices
            do {
                Logger.widget.info("Fetching fresh prices for \(refreshData.holdings.count) coins")
                let prices = try await WidgetAPIClient.fetchPrices(coinIds: refreshData.coinIds)

                // T011 (US1): Recalculate with fresh prices
                portfolioData = PortfolioRecalculator.recalculate(
                    refreshData: refreshData,
                    prices: prices
                )

                // Write updated data for widget views (so cached data is fresh)
                do {
                    try storage.writePortfolioData(portfolioData)
                    Logger.widget.info("Updated portfolio data written to storage")
                } catch {
                    Logger.widget.error("Failed to write updated portfolio data: \(error.localizedDescription)")
                    // Continue anyway - we have the fresh data in memory
                }

                Logger.widget.info("Fresh data recalculated successfully: \(portfolioData.holdings.count) holdings")
            } catch {
                // T015 (US2): Fall back to cached data on network failure
                Logger.widget.warning("Price fetch failed, falling back to cached data: \(error.localizedDescription)")

                if let cachedData = storage.readPortfolioData() {
                    portfolioData = cachedData
                    Logger.widget.info("Using cached data from \(cachedData.lastUpdated)")
                } else {
                    // No cached data available - show empty state
                    Logger.widget.warning("No cached data available, showing empty state")
                    let entry = PortfolioEntry(date: Date(), data: .empty)
                    let refreshDate = Date().addingTimeInterval(Self.refreshIntervalMinutes * 60)
                    completion(Timeline(entries: [entry], policy: .after(refreshDate)))
                    return
                }
            }

            // T012 (US1): Create timeline with single entry and 15-minute refresh policy
            let entry = PortfolioEntry(date: Date(), data: portfolioData)
            let refreshDate = Date().addingTimeInterval(Self.refreshIntervalMinutes * 60)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))

            Logger.widget.info("Timeline created, next refresh at \(refreshDate)")
            completion(timeline)
        }
    }

    // MARK: - Private Methods

    /// Creates a timeline entry from cached storage data.
    /// Returns empty state if no data is available.
    private func createEntryFromStorage() -> PortfolioEntry {
        if let data = storage.readPortfolioData() {
            Logger.widget.info("Loaded portfolio data: \(data.holdings.count) holdings")
            return .entry(data: data)
        } else {
            Logger.widget.info("No portfolio data available, showing empty state")
            return .empty()
        }
    }
}
