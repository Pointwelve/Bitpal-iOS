//
//  CandleDataPoint.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// Represents OHLC (Open, High, Low, Close) data for candlestick charts
/// Per Constitution Principle IV: Uses Decimal for all financial values
struct CandleDataPoint: Identifiable, Codable, Equatable {
    /// Unique identifier (uses timestamp)
    var id: Date { timestamp }

    /// Candle close time (X-axis)
    let timestamp: Date

    /// Opening price
    let open: Decimal

    /// Highest price during interval
    let high: Decimal

    /// Lowest price during interval
    let low: Decimal

    /// Closing price
    let close: Decimal

    // MARK: - Computed Properties

    /// True if candle closed higher than or equal to open (bullish)
    var isGreen: Bool { close >= open }

    /// True if candle closed lower than open (bearish)
    var isRed: Bool { close < open }

    /// Price movement during interval
    var priceChange: Decimal { close - open }

    /// Percentage change during interval
    var percentageChange: Decimal {
        guard open != 0 else { return 0 }
        return (priceChange / open) * 100
    }

    // MARK: - Initialization

    init(timestamp: Date, open: Decimal, high: Decimal, low: Decimal, close: Decimal) {
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
    }

    /// Create from CoinGecko OHLC API array [timestamp_ms, open, high, low, close]
    init?(from apiArray: [Double]) {
        guard apiArray.count >= 5 else { return nil }
        self.timestamp = Date(timeIntervalSince1970: apiArray[0] / 1000)
        self.open = Decimal(apiArray[1])
        self.high = Decimal(apiArray[2])
        self.low = Decimal(apiArray[3])
        self.close = Decimal(apiArray[4])
    }
}

// MARK: - Array Extension

extension Array where Element == [Double] {
    /// Convert CoinGecko OHLC array to CandleDataPoint array
    func toCandleDataPoints() -> [CandleDataPoint] {
        compactMap { CandleDataPoint(from: $0) }
    }
}

// MARK: - Candle Array Extension

extension Array where Element == CandleDataPoint {
    /// Ensure candle continuity: each candle's open equals the previous candle's close
    /// This fixes visual gaps caused by CoinGecko API returning non-continuous OHLC data
    /// Note: High/Low are adjusted if needed to ensure they still bound the open/close range
    func ensureContinuity() -> [CandleDataPoint] {
        guard count > 1 else { return self }

        var result: [CandleDataPoint] = []
        result.reserveCapacity(count)

        // First candle stays as-is
        result.append(self[0])

        // For each subsequent candle, set open to previous close
        for i in 1..<count {
            let current = self[i]
            let previousClose = result[i - 1].close

            // Adjust open to previous close
            let adjustedOpen = previousClose

            // Ensure high is at least the max of open and close
            let adjustedHigh = Swift.max(current.high, Swift.max(adjustedOpen, current.close))

            // Ensure low is at most the min of open and close
            let adjustedLow = Swift.min(current.low, Swift.min(adjustedOpen, current.close))

            let adjustedCandle = CandleDataPoint(
                timestamp: current.timestamp,
                open: adjustedOpen,
                high: adjustedHigh,
                low: adjustedLow,
                close: current.close
            )
            result.append(adjustedCandle)
        }

        return result
    }
}
