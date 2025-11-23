//
//  PortfolioSummary.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-23.
//  Closed Positions feature (003-closed-positions)
//

import Foundation

/// Aggregates portfolio performance metrics including unrealized and realized P&L.
/// This is a computed model - NOT persisted to Swift Data.
/// Computed from Holding[] (open positions) and ClosedPosition[] (closed cycles).
struct PortfolioSummary: Equatable {
    // MARK: - Open Holdings Metrics

    let totalValue: Decimal          // Sum of all open holdings' current value
    let unrealizedPnL: Decimal       // Sum of all open holdings' profit/loss

    // MARK: - Closed Positions Metrics

    let realizedPnL: Decimal         // Sum of all closed positions' realized P&L

    // MARK: - Internal Metrics

    let totalOpenCost: Decimal       // Sum of all open holdings' cost basis
    let totalClosedCost: Decimal     // Sum of all closed positions' cost basis

    // MARK: - Total Performance (Computed)

    /// Total portfolio P&L (open + closed)
    var totalPnL: Decimal {
        unrealizedPnL + realizedPnL
    }

    /// Total P&L as percentage of total cost basis
    var totalPnLPercentage: Decimal {
        let totalCostBasis = totalOpenCost + totalClosedCost
        guard totalCostBasis > 0 else { return 0 }
        return (totalPnL / totalCostBasis) * 100
    }
}

// MARK: - Computation Functions

/// Computes portfolio summary from open holdings and closed positions.
/// - Parameters:
///   - holdings: Array of active open positions
///   - closedPositions: Array of closed trading cycles
/// - Returns: PortfolioSummary with aggregated metrics
func computePortfolioSummary(
    holdings: [Holding],
    closedPositions: [ClosedPosition]
) -> PortfolioSummary {
    // Open holdings metrics
    let totalValue = holdings.reduce(0) { $0 + $1.currentValue }
    let unrealizedPnL = holdings.reduce(0) { $0 + $1.profitLoss }
    let totalOpenCost = holdings.reduce(0) { $0 + $1.totalCost }

    // Closed positions metrics
    let realizedPnL = closedPositions.reduce(0) { $0 + $1.realizedPnL }
    let totalClosedCost = closedPositions.reduce(0) { $0 + ($1.avgCostPrice * $1.totalQuantity) }

    return PortfolioSummary(
        totalValue: totalValue,
        unrealizedPnL: unrealizedPnL,
        realizedPnL: realizedPnL,
        totalOpenCost: totalOpenCost,
        totalClosedCost: totalClosedCost
    )
}
