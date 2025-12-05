//
//  Holding.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import Foundation

/// Computed user position derived from transactions
/// NOT persisted - calculated on-demand for data consistency
/// Per Constitution Principle IV: Uses Decimal for all financial values
struct Holding: Identifiable, Equatable {
    // MARK: - Stored Properties

    let id: String              // coinId
    let coin: Coin              // Full coin data with current price
    let totalAmount: Decimal    // Computed total quantity
    let avgCost: Decimal        // Computed weighted average cost
    let currentValue: Decimal   // Computed: totalAmount × currentPrice

    // MARK: - Computed Properties

    /// Absolute profit or loss in USD
    var profitLoss: Decimal {
        currentValue - (totalAmount * avgCost)
    }

    /// Profit/loss as percentage
    /// Per FR-026: Display to 2 decimal places
    var profitLossPercentage: Decimal {
        guard avgCost > 0 else { return 0 }
        return ((currentValue / (totalAmount * avgCost)) - 1) * 100
    }

    /// Total cost basis
    var totalCost: Decimal {
        totalAmount * avgCost
    }
}

// MARK: - Holdings Calculation

/// Compute holdings from transactions and current prices
/// Per Constitution Principle IV: Follows standard accounting principles
/// Per SC-005: Must complete in <100ms for 50 holdings, 500 transactions
/// Per FR-016: Excludes transactions from closed cycles
func computeHoldings(
    transactions: [Transaction],
    currentPrices: [String: Coin]
) -> [Holding] {
    // Group transactions by coinId
    let grouped = Dictionary(grouping: transactions, by: { $0.coinId })

    return grouped.compactMap { (coinId, txs) -> Holding? in
        guard let coin = currentPrices[coinId] else { return nil }

        // FR-016: Filter out transactions from closed cycles
        let openCycleTxs = filterOpenCycleTransactions(txs)

        // If no open cycle transactions, no holding exists
        guard !openCycleTxs.isEmpty else { return nil }

        var totalAmount: Decimal = 0
        var totalCost: Decimal = 0

        // First pass: calculate weighted average cost from all buys (open cycle only)
        var totalBuyAmount: Decimal = 0
        var totalBuyCost: Decimal = 0

        for tx in openCycleTxs {
            switch tx.type {
            case .buy:
                totalBuyAmount += tx.amount
                totalBuyCost += tx.amount * tx.pricePerCoin
            case .sell:
                break // Handled in second pass
            }
        }

        // Calculate weighted average cost from buys only
        let avgCost: Decimal = totalBuyAmount > 0 ? totalBuyCost / totalBuyAmount : 0

        // Second pass: calculate net holdings
        for tx in openCycleTxs {
            switch tx.type {
            case .buy:
                totalAmount += tx.amount
                totalCost += tx.amount * tx.pricePerCoin
            case .sell:
                totalAmount -= tx.amount
                // Reduce cost basis proportionally at average cost
                totalCost -= tx.amount * avgCost
            }
        }

        // Per FR-013: Hide holdings where total quantity = 0
        guard totalAmount > 0 else { return nil }
        let currentValue = totalAmount * coin.currentPrice

        return Holding(
            id: coinId,
            coin: coin,
            totalAmount: totalAmount,
            avgCost: avgCost,
            currentValue: currentValue
        )
    }
}

/// Filters transactions to include only those from the current open cycle.
/// Excludes transactions from completed (closed) cycles.
/// Per FR-016: Holdings must not include closed cycle data
/// - Parameter transactions: All transactions for a specific coin
/// - Returns: Only transactions from the current open cycle (after last close)
func filterOpenCycleTransactions(_ transactions: [Transaction]) -> [Transaction] {
    // Sort transactions by date (chronological order)
    let sortedTxs = transactions.sorted { $0.date < $1.date }

    // Track running balance and find last cycle closure index
    var runningBalance: Decimal = 0
    var lastClosureIndex: Int? = nil

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
            lastClosureIndex = index
            runningBalance = 0
        }
    }

    // If no cycle closures found, all transactions are from open cycle
    guard let closureIndex = lastClosureIndex else {
        return sortedTxs
    }

    // Return only transactions after the last closure
    // closureIndex + 1 because we want transactions AFTER the closing sell
    let openCycleStart = closureIndex + 1
    guard openCycleStart < sortedTxs.count else {
        return []  // No open cycle transactions exist
    }

    return Array(sortedTxs[openCycleStart...])
}

// MARK: - Partial Realized Gains Calculation

/// Computes realized gains from partial sales in open positions.
/// Per Amendment 2025-12-05: Realized P&L now includes partial sale gains.
/// Uses average cost method: each sell realizes (sellPrice - avgCost) × quantity
/// - Parameters:
///   - transactions: All user transactions across all coins
///   - currentPrices: Dictionary of current coin prices keyed by coinId (for validation)
/// - Returns: Total realized gains from partial sales in open positions
func computePartialRealizedGains(
    transactions: [Transaction],
    currentPrices: [String: Coin]
) -> Decimal {
    // Group transactions by coinId
    let grouped = Dictionary(grouping: transactions, by: { $0.coinId })

    var totalPartialRealizedGains: Decimal = 0

    for (coinId, txs) in grouped {
        // Skip if coin not in current prices (can't validate it's a real coin)
        guard currentPrices[coinId] != nil else { continue }

        // Get only open cycle transactions
        let openCycleTxs = filterOpenCycleTransactions(txs)

        // Skip if no open cycle (fully closed positions handled by ClosedPosition)
        guard !openCycleTxs.isEmpty else { continue }

        // Calculate weighted average cost from all buys in open cycle
        var totalBuyAmount: Decimal = 0
        var totalBuyCost: Decimal = 0

        for tx in openCycleTxs {
            if tx.type == .buy {
                totalBuyAmount += tx.amount
                totalBuyCost += tx.amount * tx.pricePerCoin
            }
        }

        let avgCost: Decimal = totalBuyAmount > 0 ? totalBuyCost / totalBuyAmount : 0

        // Calculate realized gains from each sell in open cycle
        for tx in openCycleTxs {
            if tx.type == .sell {
                // Realized gain = (sale price - avg cost) × quantity sold
                let realizedGain = (tx.pricePerCoin - avgCost) * tx.amount
                totalPartialRealizedGains += realizedGain
            }
        }
    }

    return totalPartialRealizedGains
}
