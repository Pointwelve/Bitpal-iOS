//
//  PortfolioRecalculator.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-12-11.
//  Feature: 008-widget-background-refresh
//
//  Shared between main app (tests) and widget extension for P&L recalculation.
//

import Foundation
import OSLog

/// Recalculates portfolio P&L using fresh prices and stored quantities.
/// Used by widget during timeline refresh to update values without main app.
/// Per Constitution Principle IV: Uses Decimal for all financial calculations.
enum PortfolioRecalculator {

    /// Recalculates portfolio data with fresh prices.
    /// Per data-model.md P&L Calculation Flow.
    /// - Parameters:
    ///   - refreshData: Holdings with quantities and average costs from App Group
    ///   - prices: Fresh price data from CoinGecko API
    /// - Returns: Updated WidgetPortfolioData ready for display
    static func recalculate(
        refreshData: WidgetRefreshData,
        prices: [String: CoinMarketData]
    ) -> WidgetPortfolioData {
        Logger.widget.info("Recalculating portfolio with \(refreshData.holdings.count) holdings")

        // Recalculate each holding with fresh price
        let updatedHoldings = refreshData.holdings.compactMap { holding -> WidgetHolding? in
            guard let priceData = prices[holding.coinId] else {
                Logger.widget.warning("No price data for \(holding.coinId), skipping")
                return nil
            }

            return recalculateHolding(holding: holding, priceData: priceData)
        }

        // Sort by current value descending and take top 5
        let topHoldings = updatedHoldings
            .sorted { $0.currentValue > $1.currentValue }
            .prefix(WidgetPortfolioData.maxHoldings)

        // Aggregate totals from ALL holdings (not just top 5)
        let totalValue = updatedHoldings.reduce(Decimal(0)) { $0 + $1.currentValue }
        let unrealizedPnL = updatedHoldings.reduce(Decimal(0)) { $0 + $1.pnlAmount }
        let totalPnL = unrealizedPnL + refreshData.realizedPnL

        Logger.widget.info("Recalculation complete: value=\(totalValue), unrealized=\(unrealizedPnL)")

        return WidgetPortfolioData(
            totalValue: totalValue,
            unrealizedPnL: unrealizedPnL,
            realizedPnL: refreshData.realizedPnL,
            totalPnL: totalPnL,
            holdings: Array(topHoldings),
            lastUpdated: Date()
        )
    }

    /// Recalculates a single holding with fresh price.
    /// Per data-model.md formula:
    /// - currentValue = quantity × freshPrice
    /// - costBasis = quantity × avgCost
    /// - pnlAmount = currentValue - costBasis
    /// - pnlPercentage = costBasis > 0 ? ((currentValue / costBasis) - 1) × 100 : 0
    private static func recalculateHolding(
        holding: WidgetRefreshData.RefreshableHolding,
        priceData: CoinMarketData
    ) -> WidgetHolding {
        let currentValue = holding.quantity * priceData.currentPrice
        let costBasis = holding.quantity * holding.avgCost
        let pnlAmount = currentValue - costBasis

        // Avoid division by zero - if cost basis is 0, P&L % is 0
        let pnlPercentage: Decimal
        if costBasis > 0 {
            pnlPercentage = ((currentValue / costBasis) - 1) * 100
        } else {
            pnlPercentage = 0
        }

        return WidgetHolding(
            id: holding.coinId,
            symbol: holding.symbol.uppercased(),
            name: holding.name,
            currentValue: currentValue,
            pnlAmount: pnlAmount,
            pnlPercentage: pnlPercentage
        )
    }
}
