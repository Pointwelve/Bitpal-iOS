//
//  ChartDataPoint.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// Represents a single price point in time for line charts
/// Per Constitution Principle IV: Uses Decimal for all financial values
struct ChartDataPoint: Identifiable, Codable, Equatable {
    /// Unique identifier (uses timestamp)
    var id: Date { timestamp }

    /// Point in time (X-axis)
    let timestamp: Date

    /// Price at this timestamp (Y-axis)
    let price: Decimal

    // MARK: - Initialization

    init(timestamp: Date, price: Decimal) {
        self.timestamp = timestamp
        self.price = price
    }

    /// Create from CoinGecko API array [timestamp_ms, price]
    init?(from apiArray: [Double]) {
        guard apiArray.count >= 2 else { return nil }
        self.timestamp = Date(timeIntervalSince1970: apiArray[0] / 1000)
        self.price = Decimal(apiArray[1])
    }
}

// MARK: - Array Extension

extension Array where Element == [Double] {
    /// Convert CoinGecko prices array to ChartDataPoint array
    func toChartDataPoints() -> [ChartDataPoint] {
        compactMap { ChartDataPoint(from: $0) }
    }
}
