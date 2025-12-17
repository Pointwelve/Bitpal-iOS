//
//  CoinMarketData.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-12-11.
//  Feature: 008-widget-background-refresh
//
//  Shared between main app and widget extension for P&L recalculation.
//

import Foundation

/// Coin market data from CoinGecko API response.
/// Contains only the fields needed for widget P&L calculation.
/// Used by both widget extension and tests.
struct CoinMarketData: Codable, Sendable, Equatable {
    /// CoinGecko coin ID (e.g., "bitcoin")
    let id: String

    /// Trading symbol (e.g., "btc")
    let symbol: String

    /// Full coin name (e.g., "Bitcoin")
    let name: String

    /// Current price in USD
    let currentPrice: Decimal

    /// 24-hour price change percentage (optional, may be nil)
    let priceChangePercentage24h: Decimal?

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
    }
}
