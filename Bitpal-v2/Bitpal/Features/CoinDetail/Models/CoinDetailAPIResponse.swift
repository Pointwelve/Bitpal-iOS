//
//  CoinDetailAPIResponse.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// API response structure for /coins/{id} endpoint
/// Maps nested JSON structure to flat CoinDetail model
struct CoinDetailAPIResponse: Codable {
    let id: String
    let symbol: String
    let name: String
    let image: ImageURLs?
    let marketData: MarketData?
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case marketData = "market_data"
        case lastUpdated = "last_updated"
    }

    // MARK: - Nested Types

    struct ImageURLs: Codable {
        let thumb: String?
        let small: String?
        let large: String?
    }

    struct MarketData: Codable {
        let currentPrice: [String: Double]?
        let priceChangePercentage24h: Double?
        let marketCap: [String: Double]?
        let totalVolume: [String: Double]?
        let circulatingSupply: Double?

        enum CodingKeys: String, CodingKey {
            case currentPrice = "current_price"
            case priceChangePercentage24h = "price_change_percentage_24h"
            case marketCap = "market_cap"
            case totalVolume = "total_volume"
            case circulatingSupply = "circulating_supply"
        }
    }

    // MARK: - Conversion

    /// Convert API response to CoinDetail model
    /// Per Constitution Principle IV: Converts Double to Decimal for financial values
    func toCoinDetail() -> CoinDetail {
        // Parse image URL
        let imageURL: URL?
        if let large = image?.large {
            imageURL = URL(string: large)
        } else {
            imageURL = nil
        }

        // Parse current price (USD)
        let currentPrice: Decimal
        if let priceDouble = marketData?.currentPrice?["usd"] {
            currentPrice = Decimal(priceDouble)
        } else {
            currentPrice = 0
        }

        // Parse 24h change
        let priceChange24h: Decimal
        if let changeDouble = marketData?.priceChangePercentage24h {
            priceChange24h = Decimal(changeDouble)
        } else {
            priceChange24h = 0
        }

        // Parse market cap (USD)
        let marketCap: Decimal?
        if let mcDouble = marketData?.marketCap?["usd"] {
            marketCap = Decimal(mcDouble)
        } else {
            marketCap = nil
        }

        // Parse total volume (USD)
        let totalVolume: Decimal?
        if let volDouble = marketData?.totalVolume?["usd"] {
            totalVolume = Decimal(volDouble)
        } else {
            totalVolume = nil
        }

        // Parse circulating supply
        let circulatingSupply: Decimal?
        if let supplyDouble = marketData?.circulatingSupply {
            circulatingSupply = Decimal(supplyDouble)
        } else {
            circulatingSupply = nil
        }

        // Parse last updated timestamp
        let lastUpdatedDate: Date
        if let dateString = lastUpdated {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            lastUpdatedDate = formatter.date(from: dateString) ?? Date()
        } else {
            lastUpdatedDate = Date()
        }

        return CoinDetail(
            id: id,
            symbol: symbol,
            name: name,
            image: imageURL,
            currentPrice: currentPrice,
            priceChange24h: priceChange24h,
            marketCap: marketCap,
            totalVolume: totalVolume,
            circulatingSupply: circulatingSupply,
            lastUpdated: lastUpdatedDate
        )
    }
}
