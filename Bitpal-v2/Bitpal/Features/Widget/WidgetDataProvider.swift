//
//  WidgetDataProvider.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import Foundation
import WidgetKit
import OSLog

/// Orchestrates widget data persistence from main app.
/// Called by PortfolioViewModel after portfolio updates.
/// Per Constitution Principle III: Singleton service pattern.
@MainActor
final class WidgetDataProvider {
    // MARK: - Singleton

    static let shared = WidgetDataProvider()

    // MARK: - Dependencies

    private let storage = AppGroupStorage.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Updates widget data with current portfolio state.
    /// Should be called after portfolio load/refresh and transaction changes.
    /// Also writes refresh data so widget can recalculate P&L with fresh prices.
    /// - Parameters:
    ///   - summary: Current portfolio summary
    ///   - holdings: Current holdings list
    func updateWidgetData(
        summary: PortfolioSummary,
        holdings: [Holding]
    ) {
        // Prepare and write display data
        let widgetData = prepareWidgetData(summary: summary, holdings: holdings)

        do {
            try storage.writePortfolioData(widgetData)
            Logger.widget.info("Widget data updated: total=\(widgetData.totalValue), holdings=\(widgetData.holdings.count)")
        } catch {
            Logger.widget.error("Failed to update widget data: \(error.localizedDescription)")
        }

        // Prepare and write refresh data (quantities for recalculation)
        let refreshData = prepareRefreshData(summary: summary, holdings: holdings)

        do {
            try storage.writeRefreshData(refreshData)
            Logger.widget.info("Refresh data updated: \(refreshData.holdings.count) holdings")
        } catch {
            Logger.widget.error("Failed to update refresh data: \(error.localizedDescription)")
        }
    }

    /// Prepares refresh data for widget to recalculate P&L with fresh prices.
    /// - Parameters:
    ///   - summary: Current portfolio summary (for realized P&L)
    ///   - holdings: Current holdings list
    /// - Returns: WidgetRefreshData with quantities and costs
    private func prepareRefreshData(
        summary: PortfolioSummary,
        holdings: [Holding]
    ) -> WidgetRefreshData {
        let refreshableHoldings = holdings.map { holding in
            WidgetRefreshData.RefreshableHolding(
                coinId: holding.id,
                symbol: holding.coin.symbol,
                name: holding.coin.name,
                quantity: holding.totalAmount,
                avgCost: holding.avgCost
            )
        }

        return WidgetRefreshData(
            holdings: refreshableHoldings,
            realizedPnL: summary.realizedPnL
        )
    }

    /// Triggers a reload of all widget timelines.
    /// Should be called after data changes that affect widget display.
    func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
        Logger.widget.info("Widget timelines reload triggered")
    }

    /// Combines data update and timeline reload.
    /// Convenience method for common use case.
    /// - Parameters:
    ///   - summary: Current portfolio summary
    ///   - holdings: Current holdings list
    func updateAndReloadWidgets(
        summary: PortfolioSummary,
        holdings: [Holding]
    ) {
        updateWidgetData(summary: summary, holdings: holdings)
        reloadWidgetTimelines()
    }

    /// Clears widget data and reloads timelines.
    /// Called when user clears all portfolio data.
    func clearWidgetData() {
        do {
            try storage.clearAllWidgetData()
            reloadWidgetTimelines()
            Logger.widget.info("Widget data cleared and timelines reloaded")
        } catch {
            Logger.widget.error("Failed to clear widget data: \(error.localizedDescription)")
        }
    }
}
