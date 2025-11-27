//
//  WidgetDataTransformer.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import Foundation

/// Transforms app models to widget-optimized format.
/// Extracts only the data needed for widget display to minimize storage and memory.
/// Per Constitution Principle IV: Widget calculations consistent with main app.

/// Transforms portfolio data to widget-optimized format.
/// - Parameters:
///   - summary: Portfolio summary with P&L totals
///   - holdings: All holdings sorted by value descending
/// - Returns: Widget-optimized portfolio data with top 5 holdings
func prepareWidgetData(
    summary: PortfolioSummary,
    holdings: [Holding]
) -> WidgetPortfolioData {
    // Take top 5 holdings by current value (already sorted by caller)
    let topHoldings = holdings
        .sorted { $0.currentValue > $1.currentValue }
        .prefix(WidgetPortfolioData.maxHoldings)
        .map { holding in
            WidgetHolding(
                id: holding.id,
                symbol: holding.coin.symbol.uppercased(),
                name: holding.coin.name,
                currentValue: holding.currentValue,
                pnlAmount: holding.profitLoss,
                pnlPercentage: holding.profitLossPercentage
            )
        }

    return WidgetPortfolioData(
        totalValue: summary.totalValue,
        unrealizedPnL: summary.unrealizedPnL,
        realizedPnL: summary.realizedPnL,
        totalPnL: summary.totalPnL,
        holdings: Array(topHoldings),
        lastUpdated: Date()
    )
}
