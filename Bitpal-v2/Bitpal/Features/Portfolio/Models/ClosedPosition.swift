//
//  ClosedPosition.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-23.
//  Closed Positions feature (003-closed-positions)
//

import Foundation

/// Represents a single completed buy-to-sell trading cycle for a specific cryptocurrency.
/// This is a computed model - NOT persisted to Swift Data.
/// Computed from Transaction records where total buy quantity equals total sell quantity for a cycle.
struct ClosedPosition: Identifiable, Equatable {
    // MARK: - Identity

    let id: UUID                    // Unique identifier for this closed cycle
    let coinId: String              // CoinGecko coin ID (e.g., "bitcoin")
    let coin: Coin                  // Full coin details (name, symbol, current price)

    // MARK: - Cycle Metrics

    let totalQuantity: Decimal      // Total amount traded in this cycle
    let avgCostPrice: Decimal       // Weighted average buy price for this cycle
    let avgSalePrice: Decimal       // Weighted average sell price for this cycle
    let closedDate: Date            // Date of final sell transaction that closed cycle

    // MARK: - Source Transactions

    let cycleTransactions: [Transaction]  // All transactions for this cycle

    // MARK: - P&L Metrics (Computed)

    /// Realized profit/loss in USD
    var realizedPnL: Decimal {
        (avgSalePrice - avgCostPrice) * totalQuantity
    }

    /// Realized profit/loss as percentage
    var realizedPnLPercentage: Decimal {
        guard avgCostPrice > 0 else { return 0 }
        return ((avgSalePrice / avgCostPrice) - 1) * 100
    }
}

// MARK: - Computation Functions

/// Computes closed positions from transactions using cycle detection algorithm.
/// - Parameters:
///   - transactions: All user transactions across all coins
///   - currentPrices: Dictionary of current coin prices keyed by coinId
/// - Returns: Array of closed trading cycles, sorted by close date (most recent first)
func computeClosedPositions(
    transactions: [Transaction],
    currentPrices: [String: Coin]
) -> [ClosedPosition] {
    // Step 1: Group transactions by coinId
    let grouped = Dictionary(grouping: transactions, by: { $0.coinId })

    var closedPositions: [ClosedPosition] = []

    // Step 2: For each coin, detect closed cycles
    for (coinId, txs) in grouped {
        guard let coin = currentPrices[coinId] else { continue }

        // Sort transactions by date (chronological order)
        let sortedTxs = txs.sorted { $0.date < $1.date }

        // Step 3: Track running balance and detect cycle closures
        var cycleStart = 0
        var runningBalance: Decimal = 0

        for (index, tx) in sortedTxs.enumerated() {
            // Update running balance
            switch tx.type {
            case .buy:
                runningBalance += tx.amount
            case .sell:
                runningBalance -= tx.amount
            }

            // Check if cycle closed (balance within tolerance of zero)
            if abs(runningBalance) < 0.00000001 {
                // Extract cycle transactions
                let cycleTxs = Array(sortedTxs[cycleStart...index])

                // Compute cycle metrics
                if let closedPos = computeCycleMetrics(
                    coinId: coinId,
                    coin: coin,
                    transactions: cycleTxs,
                    closeDate: tx.date
                ) {
                    closedPositions.append(closedPos)
                }

                // Reset for next cycle
                cycleStart = index + 1
                runningBalance = 0
            }
        }
    }

    // Step 4: Sort by close date (most recent first)
    return closedPositions.sorted { $0.closedDate > $1.closedDate }
}

/// Helper function to compute metrics for a single closed cycle.
/// - Parameters:
///   - coinId: CoinGecko coin ID
///   - coin: Full coin details
///   - transactions: Transactions for this cycle
///   - closeDate: Date of final sell transaction
/// - Returns: ClosedPosition if valid cycle, nil if invalid
private func computeCycleMetrics(
    coinId: String,
    coin: Coin,
    transactions: [Transaction],
    closeDate: Date
) -> ClosedPosition? {
    var totalBuyAmount: Decimal = 0
    var totalBuyCost: Decimal = 0
    var totalSellAmount: Decimal = 0
    var totalSellRevenue: Decimal = 0

    // Calculate weighted averages
    for tx in transactions {
        switch tx.type {
        case .buy:
            totalBuyAmount += tx.amount
            totalBuyCost += tx.amount * tx.pricePerCoin
        case .sell:
            totalSellAmount += tx.amount
            totalSellRevenue += tx.amount * tx.pricePerCoin
        }
    }

    guard totalBuyAmount > 0 && totalSellAmount > 0 else {
        return nil  // Invalid cycle
    }

    let avgCostPrice = totalBuyCost / totalBuyAmount
    let avgSalePrice = totalSellRevenue / totalSellAmount

    return ClosedPosition(
        id: UUID(),
        coinId: coinId,
        coin: coin,
        totalQuantity: totalBuyAmount,  // Use buy amount (should equal sell amount)
        avgCostPrice: avgCostPrice,
        avgSalePrice: avgSalePrice,
        closedDate: closeDate,
        cycleTransactions: transactions
    )
}
