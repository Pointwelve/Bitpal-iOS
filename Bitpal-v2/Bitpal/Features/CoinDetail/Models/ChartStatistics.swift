//
//  ChartStatistics.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// Computed statistics for chart data
/// Per Constitution Principle IV: Uses Decimal for all financial values
struct ChartStatistics {
    /// Highest price in the period
    let periodHigh: Decimal

    /// Lowest price in the period
    let periodLow: Decimal

    /// Price at the start of the period
    let startPrice: Decimal

    /// Price at the end of the period (current)
    let endPrice: Decimal

    /// Absolute price change
    var priceChange: Decimal {
        endPrice - startPrice
    }

    /// Percentage price change
    var percentageChange: Decimal {
        guard startPrice != 0 else { return 0 }
        return (priceChange / startPrice) * 100
    }

    /// True if price increased or stayed the same over the period
    var isPositive: Bool {
        priceChange >= 0
    }

    // MARK: - Factory Methods

    /// Calculate statistics from line chart data
    static func from(lineData: [ChartDataPoint]) -> ChartStatistics? {
        guard let first = lineData.first,
              let last = lineData.last else {
            return nil
        }

        let prices = lineData.map { $0.price }
        guard let high = prices.max(),
              let low = prices.min() else {
            return nil
        }

        return ChartStatistics(
            periodHigh: high,
            periodLow: low,
            startPrice: first.price,
            endPrice: last.price
        )
    }

    /// Calculate statistics from candlestick data
    static func from(candleData: [CandleDataPoint]) -> ChartStatistics? {
        guard let first = candleData.first,
              let last = candleData.last else {
            return nil
        }

        let highs = candleData.map { $0.high }
        let lows = candleData.map { $0.low }

        guard let high = highs.max(),
              let low = lows.min() else {
            return nil
        }

        return ChartStatistics(
            periodHigh: high,
            periodLow: low,
            startPrice: first.open,
            endPrice: last.close
        )
    }
}
