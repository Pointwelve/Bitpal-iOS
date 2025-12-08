//
//  CoinDetail.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// Extended coin details for the coin detail screen
/// Includes market statistics beyond basic price data
/// Per Constitution Principle IV: Uses Decimal for all financial values
struct CoinDetail: Identifiable, Codable, Equatable {
    /// CoinGecko unique identifier (e.g., "bitcoin")
    let id: String

    /// Trading symbol (e.g., "btc")
    let symbol: String

    /// Display name (e.g., "Bitcoin")
    let name: String

    /// Logo URL
    let image: URL?

    /// Current USD price
    var currentPrice: Decimal

    /// 24-hour price change percentage
    var priceChange24h: Decimal

    /// Market capitalization in USD
    var marketCap: Decimal?

    /// 24-hour trading volume in USD
    var totalVolume: Decimal?

    /// Coins in circulation
    var circulatingSupply: Decimal?

    /// Last price update timestamp
    var lastUpdated: Date

    // MARK: - Memberwise Initializer

    init(
        id: String,
        symbol: String,
        name: String,
        image: URL? = nil,
        currentPrice: Decimal,
        priceChange24h: Decimal,
        marketCap: Decimal? = nil,
        totalVolume: Decimal? = nil,
        circulatingSupply: Decimal? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.currentPrice = currentPrice
        self.priceChange24h = priceChange24h
        self.marketCap = marketCap
        self.totalVolume = totalVolume
        self.circulatingSupply = circulatingSupply
        self.lastUpdated = lastUpdated
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice = "current_price"
        case priceChange24h = "price_change_percentage_24h"
        case marketCap = "market_cap"
        case totalVolume = "total_volume"
        case circulatingSupply = "circulating_supply"
        case lastUpdated = "last_updated"
    }

    // MARK: - Custom Decoding (Double → Decimal)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        image = try container.decodeIfPresent(URL.self, forKey: .image)

        // Convert Double to Decimal for financial accuracy
        let priceDouble = try container.decode(Double.self, forKey: .currentPrice)
        currentPrice = Decimal(priceDouble)

        let changeDouble = try container.decodeIfPresent(Double.self, forKey: .priceChange24h) ?? 0
        priceChange24h = Decimal(changeDouble)

        if let mcDouble = try container.decodeIfPresent(Double.self, forKey: .marketCap) {
            marketCap = Decimal(mcDouble)
        } else {
            marketCap = nil
        }

        if let volDouble = try container.decodeIfPresent(Double.self, forKey: .totalVolume) {
            totalVolume = Decimal(volDouble)
        } else {
            totalVolume = nil
        }

        if let supplyDouble = try container.decodeIfPresent(Double.self, forKey: .circulatingSupply) {
            circulatingSupply = Decimal(supplyDouble)
        } else {
            circulatingSupply = nil
        }

        let dateString = try container.decode(String.self, forKey: .lastUpdated)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        lastUpdated = formatter.date(from: dateString) ?? Date()
    }

    // MARK: - Equatable

    static func == (lhs: CoinDetail, rhs: CoinDetail) -> Bool {
        lhs.id == rhs.id &&
        lhs.currentPrice == rhs.currentPrice &&
        lhs.priceChange24h == rhs.priceChange24h
    }
}
