//
//  CoinModelTests.swift
//  BitpalTests
//
//  Created by Bitpal Development on 8/11/25.
//

import XCTest
@testable import Bitpal

/// Unit tests for Coin model JSON decoding
/// Per Constitution Principle IV: Test API response parsing (REQUIRED)
final class CoinModelTests: XCTestCase {

    func testCoinJSONDecoding_validData_succeeds() throws {
        // Given: Valid CoinGecko API response
        let json = """
        {
            "id": "bitcoin",
            "symbol": "btc",
            "name": "Bitcoin",
            "current_price": 45000.50,
            "price_change_percentage_24h": 2.5,
            "last_updated": "2025-01-15T10:30:00.000Z"
        }
        """.data(using: .utf8)!

        // When: Decoding JSON to Coin
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let coin = try decoder.decode(Coin.self, from: json)

        // Then: All fields decoded correctly
        XCTAssertEqual(coin.id, "bitcoin")
        XCTAssertEqual(coin.symbol, "btc")
        XCTAssertEqual(coin.name, "Bitcoin")
        XCTAssertEqual(coin.currentPrice, Decimal(45000.50))
        XCTAssertEqual(coin.priceChange24h, Decimal(2.5))
        XCTAssertNotNil(coin.lastUpdated)
    }

    func testCoinJSONDecoding_decimalPrecision_maintained() throws {
        // Given: JSON with precise decimal values
        let json = """
        {
            "id": "bitcoin",
            "symbol": "btc",
            "name": "Bitcoin",
            "current_price": 45000.12345678,
            "price_change_percentage_24h": -3.456789,
            "last_updated": "2025-01-15T10:30:00.000Z"
        }
        """.data(using: .utf8)!

        // When: Decoding to Coin
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let coin = try decoder.decode(Coin.self, from: json)

        // Then: Decimal precision maintained (NOT truncated to Float precision)
        // This verifies Constitution Principle IV: MUST use Decimal (NOT Double)
        XCTAssertEqual(coin.currentPrice, Decimal(45000.12345678))
        XCTAssertEqual(coin.priceChange24h, Decimal(-3.456789))
    }

    func testCoinJSONDecoding_missingOptionalFields_usesDefaults() {
        // Given: JSON with missing optional fields (current_price, market_cap)
        // Decoder is lenient per commit "Make Coin decoder more lenient for null API values"
        let json = """
        {
            "id": "bitcoin",
            "symbol": "btc",
            "name": "Bitcoin",
            "price_change_percentage_24h": 2.5,
            "last_updated": "2025-01-15T10:30:00.000Z"
        }
        """.data(using: .utf8)!

        // When: Decoding with missing fields
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let coin = try? decoder.decode(Coin.self, from: json)

        // Then: Should succeed with default values for missing fields
        XCTAssertNotNil(coin)
        XCTAssertEqual(coin?.id, "bitcoin")
        XCTAssertEqual(coin?.currentPrice, 0) // Default when missing
        XCTAssertEqual(coin?.marketCap, nil)  // Optional field
    }

    func testCoinEquality_sameData_equals() {
        // Given: Two coins with identical data
        let coin1 = Coin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            currentPrice: Decimal(45000.50),
            priceChange24h: Decimal(2.5),
            lastUpdated: Date()
        )

        let coin2 = Coin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            currentPrice: Decimal(45000.50),
            priceChange24h: Decimal(2.5),
            lastUpdated: Date()
        )

        // Then: Coins are equal
        XCTAssertEqual(coin1, coin2)
    }

    func testCoinEquality_differentPrice_notEqual() {
        // Given: Two coins with different prices
        let coin1 = Coin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            currentPrice: Decimal(45000.50),
            priceChange24h: Decimal(2.5),
            lastUpdated: Date()
        )

        let coin2 = Coin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            currentPrice: Decimal(46000.00), // Different price
            priceChange24h: Decimal(2.5),
            lastUpdated: Date()
        )

        // Then: Coins are NOT equal
        XCTAssertNotEqual(coin1, coin2)
    }
}
