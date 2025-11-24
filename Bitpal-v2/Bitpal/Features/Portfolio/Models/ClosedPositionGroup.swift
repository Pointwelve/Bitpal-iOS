//
//  ClosedPositionGroup.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-24.
//  Closed Positions Grouping feature - FR-019, FR-020, FR-021, FR-022
//

import Foundation

/// Represents an aggregated view of all closed trading cycles for a specific cryptocurrency.
/// This is a computed model - NOT persisted to Swift Data.
/// Groups multiple ClosedPosition entries by coin for UI navigation.
/// Per FR-019: Closed positions grouped by coin
/// Per FR-020: Displays aggregated metrics (cycle count, total P&L)
struct ClosedPositionGroup: Identifiable, Equatable {
    // MARK: - Identity

    let id: UUID                    // Unique identifier for this group
    let coinId: String              // CoinGecko coin ID (e.g., "bitcoin")
    let coin: Coin                  // Full coin details (name, symbol, current price)

    // MARK: - Aggregated Metrics

    let cycleCount: Int             // Number of closed cycles for this coin
    let totalRealizedPnL: Decimal   // Sum of all cycle P&Ls
    let totalRealizedPnLPercentage: Decimal  // Weighted average percentage
    let mostRecentCloseDate: Date   // Date of most recent cycle close

    // MARK: - Source Data

    let closedPositions: [ClosedPosition]  // All cycles for this coin

    // MARK: - Computed Properties

    /// Total amount invested across all cycles (for percentage calculation)
    var totalInvested: Decimal {
        closedPositions.reduce(0) { $0 + ($1.avgCostPrice * $1.totalQuantity) }
    }

    /// Total revenue from all cycles
    var totalRevenue: Decimal {
        closedPositions.reduce(0) { $0 + ($1.avgSalePrice * $1.totalQuantity) }
    }
}

// MARK: - Computation Functions

/// Computes closed position groups from individual closed positions.
/// Groups by coin and aggregates metrics for UI display.
/// Per FR-019, FR-020, FR-022
/// - Parameter closedPositions: Array of individual closed trading cycles
/// - Returns: Array of grouped positions sorted by most recent close date
func computeClosedPositionGroups(
    closedPositions: [ClosedPosition]
) -> [ClosedPositionGroup] {
    // Step 1: Group closed positions by coinId
    let grouped = Dictionary(grouping: closedPositions, by: { $0.coinId })

    // Step 2: Create groups with aggregated metrics
    let groups = grouped.compactMap { (coinId, positions) -> ClosedPositionGroup? in
        guard let coin = positions.first?.coin else { return nil }

        // Sort positions by close date (most recent first) for this coin
        let sortedPositions = positions.sorted { $0.closedDate > $1.closedDate }

        // Get most recent close date
        guard let mostRecentCloseDate = sortedPositions.first?.closedDate else {
            return nil
        }

        // Calculate aggregated metrics
        let cycleCount = positions.count

        // Total P&L: Sum of all cycle P&Ls
        let totalRealizedPnL = positions.reduce(0) { $0 + $1.realizedPnL }

        // Calculate weighted average percentage
        let totalInvested = positions.reduce(0) { $0 + ($1.avgCostPrice * $1.totalQuantity) }
        let totalRevenue = positions.reduce(0) { $0 + ($1.avgSalePrice * $1.totalQuantity) }

        let totalRealizedPnLPercentage: Decimal
        if totalInvested > 0 {
            totalRealizedPnLPercentage = ((totalRevenue / totalInvested) - 1) * 100
        } else {
            totalRealizedPnLPercentage = 0
        }

        return ClosedPositionGroup(
            id: UUID(),
            coinId: coinId,
            coin: coin,
            cycleCount: cycleCount,
            totalRealizedPnL: totalRealizedPnL,
            totalRealizedPnLPercentage: totalRealizedPnLPercentage,
            mostRecentCloseDate: mostRecentCloseDate,
            closedPositions: sortedPositions  // Already sorted within group
        )
    }

    // Step 3: Sort groups by most recent close date (FR-022)
    return groups.sorted { $0.mostRecentCloseDate > $1.mostRecentCloseDate }
}
