//
//  CachedChartData.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation
import SwiftData

/// Cached chart data for offline support
/// Per Constitution Principle III: Uses Swift Data for persistence (NOT Core Data)
@Model
final class CachedChartData {
    /// Unique cache key: "{coinId}-{chartType}-{timeRange}"
    /// Example: "bitcoin-line-1D"
    @Attribute(.unique) var cacheKey: String

    /// JSON-encoded chart data ([ChartDataPoint] or [CandleDataPoint])
    var pricesJSON: Data

    /// When this data was cached
    var cachedAt: Date

    /// When this cache entry expires
    var expiresAt: Date

    // MARK: - Initialization

    init(cacheKey: String, pricesJSON: Data, ttl: TimeInterval) {
        self.cacheKey = cacheKey
        self.pricesJSON = pricesJSON
        self.cachedAt = Date()
        self.expiresAt = Date().addingTimeInterval(ttl)
    }

    // MARK: - Computed Properties

    /// True if cache has expired
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// Time remaining until expiration
    var timeUntilExpiration: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }

    // MARK: - Factory Methods

    /// Create cache key from components
    static func makeCacheKey(coinId: String, chartType: ChartType, timeRange: ChartTimeRange) -> String {
        "\(coinId)-\(chartType.rawValue.lowercased())-\(timeRange.rawValue)"
    }

    /// Create cache entry for line chart data
    static func forLineChart(
        coinId: String,
        timeRange: ChartTimeRange,
        data: [ChartDataPoint]
    ) throws -> CachedChartData {
        let encoder = JSONEncoder()
        let json = try encoder.encode(data)
        let key = makeCacheKey(coinId: coinId, chartType: .line, timeRange: timeRange)
        return CachedChartData(cacheKey: key, pricesJSON: json, ttl: timeRange.cacheTTL)
    }

    /// Create cache entry for candlestick data
    static func forCandleChart(
        coinId: String,
        timeRange: ChartTimeRange,
        data: [CandleDataPoint]
    ) throws -> CachedChartData {
        let encoder = JSONEncoder()
        let json = try encoder.encode(data)
        let key = makeCacheKey(coinId: coinId, chartType: .candle, timeRange: timeRange)
        return CachedChartData(cacheKey: key, pricesJSON: json, ttl: timeRange.cacheTTL)
    }

    // MARK: - Data Retrieval

    /// Decode cached line chart data
    func decodeLineChartData() throws -> [ChartDataPoint] {
        let decoder = JSONDecoder()
        return try decoder.decode([ChartDataPoint].self, from: pricesJSON)
    }

    /// Decode cached candlestick data
    func decodeCandleChartData() throws -> [CandleDataPoint] {
        let decoder = JSONDecoder()
        return try decoder.decode([CandleDataPoint].self, from: pricesJSON)
    }
}
