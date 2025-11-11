//
//  Coin.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation

/// Represents a cryptocurrency from CoinGecko API with current market data
/// Per Constitution Principle IV: MUST use Decimal for all financial values
struct Coin: Identifiable, Codable, Equatable {
    // MARK: - Properties

    /// Unique CoinGecko identifier (e.g., "bitcoin")
    let id: String

    /// Ticker symbol (e.g., "btc")
    let symbol: String

    /// Human-readable display name (e.g., "Bitcoin")
    let name: String

    /// Current price in USD (Decimal per Constitution)
    var currentPrice: Decimal

    /// 24-hour price change percentage (Decimal per Constitution)
    var priceChange24h: Decimal

    /// Timestamp of last price update from API
    var lastUpdated: Date

    /// Market capitalization in USD (Decimal per Constitution)
    /// Used for sorting search results (FR-018)
    var marketCap: Decimal?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case currentPrice = "current_price"
        case priceChange24h = "price_change_percentage_24h"
        case lastUpdated = "last_updated"
        case marketCap = "market_cap"
    }

    // MARK: - Custom Decoding

    /// Custom decoder to handle optional marketCap and convert Double to Decimal
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)

        // Decode financial values as Double first, then convert to Decimal
        let priceDouble = try container.decode(Double.self, forKey: .currentPrice)
        currentPrice = Decimal(priceDouble)

        let changeDouble = try container.decode(Double.self, forKey: .priceChange24h)
        priceChange24h = Decimal(changeDouble)

        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)

        // Market cap is optional and might be null
        if let marketCapDouble = try container.decodeIfPresent(Double.self, forKey: .marketCap) {
            marketCap = Decimal(marketCapDouble)
        } else {
            marketCap = nil
        }
    }

    // MARK: - Equatable Conformance

    /// Two coins are equal if id matches and price data matches
    /// Optimized for SwiftUI diffing and efficient UI updates
    static func == (lhs: Coin, rhs: Coin) -> Bool {
        lhs.id == rhs.id &&
        lhs.currentPrice == rhs.currentPrice &&
        lhs.priceChange24h == rhs.priceChange24h
    }
}
