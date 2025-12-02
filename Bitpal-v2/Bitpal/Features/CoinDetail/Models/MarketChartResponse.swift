//
//  MarketChartResponse.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// API response structure for /coins/{id}/market_chart endpoint
/// Contains price, market cap, and volume time series data
struct MarketChartResponse: Codable {
    /// Array of [timestamp_ms, price] pairs
    let prices: [[Double]]

    /// Array of [timestamp_ms, market_cap] pairs (optional)
    let marketCaps: [[Double]]?

    /// Array of [timestamp_ms, volume] pairs (optional)
    let totalVolumes: [[Double]]?

    enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }

    // MARK: - Conversion

    /// Convert prices array to ChartDataPoint array
    func toChartDataPoints() -> [ChartDataPoint] {
        prices.toChartDataPoints()
    }
}

/// API response structure for /coins/{id}/ohlc endpoint
/// Contains OHLC (Open, High, Low, Close) candlestick data
/// Note: This endpoint returns a raw array, not an object
typealias OHLCResponse = [[Double]]

// MARK: - OHLCResponse Extension

extension OHLCResponse {
    /// Convert OHLC array to CandleDataPoint array
    func toCandles() -> [CandleDataPoint] {
        toCandleDataPoints()
    }
}
