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
func computeHoldings(
    transactions: [Transaction],
    currentPrices: [String: Coin]
) -> [Holding] {
    // Group transactions by coinId
    let grouped = Dictionary(grouping: transactions, by: { $0.coinId })

    return grouped.compactMap { (coinId, txs) -> Holding? in
        guard let coin = currentPrices[coinId] else { return nil }

        var totalAmount: Decimal = 0
        var totalCost: Decimal = 0

        // First pass: calculate weighted average cost from all buys
        var totalBuyAmount: Decimal = 0
        var totalBuyCost: Decimal = 0

        for tx in txs {
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
        for tx in txs {
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
