//
//  AppGroupStorageTests.swift
//  BitpalTests
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import XCTest
@testable import Bitpal

/// Tests for AppGroupStorage JSON read/write operations.
/// Note: These tests may not work in simulator without proper App Group entitlements.
/// Integration testing with real App Group requires device or proper provisioning.
final class AppGroupStorageTests: XCTestCase {

    // MARK: - Test Data

    private var sampleData: WidgetPortfolioData {
        WidgetPortfolioData(
            totalValue: Decimal(125000.50),
            unrealizedPnL: Decimal(15000.00),
            realizedPnL: Decimal(5000.00),
            totalPnL: Decimal(20000.00),
            holdings: [
                WidgetHolding(
                    id: "bitcoin",
                    symbol: "BTC",
                    name: "Bitcoin",
                    currentValue: Decimal(100000.00),
                    pnlAmount: Decimal(12000.00),
                    pnlPercentage: Decimal(13.64)
                ),
                WidgetHolding(
                    id: "ethereum",
                    symbol: "ETH",
                    name: "Ethereum",
                    currentValue: Decimal(25000.50),
                    pnlAmount: Decimal(3000.00),
                    pnlPercentage: Decimal(13.64)
                )
            ],
            lastUpdated: Date()
        )
    }

    // MARK: - JSON Encoding/Decoding Tests

    func testWidgetPortfolioDataEncoding() throws {
        // Given
        let data = sampleData

        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)

        // Then
        XCTAssertGreaterThan(jsonData.count, 0)

        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["totalValue"])
        XCTAssertNotNil(json?["holdings"])
        XCTAssertNotNil(json?["lastUpdated"])
    }

    func testWidgetPortfolioDataDecoding() throws {
        // Given
        let originalData = sampleData

        // When - encode then decode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(originalData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedData = try decoder.decode(WidgetPortfolioData.self, from: jsonData)

        // Then
        XCTAssertEqual(decodedData.totalValue, originalData.totalValue)
        XCTAssertEqual(decodedData.unrealizedPnL, originalData.unrealizedPnL)
        XCTAssertEqual(decodedData.realizedPnL, originalData.realizedPnL)
        XCTAssertEqual(decodedData.totalPnL, originalData.totalPnL)
        XCTAssertEqual(decodedData.holdings.count, originalData.holdings.count)
    }

    func testWidgetHoldingEncoding() throws {
        // Given
        let holding = WidgetHolding(
            id: "bitcoin",
            symbol: "BTC",
            name: "Bitcoin",
            currentValue: Decimal(50000),
            pnlAmount: Decimal(5000),
            pnlPercentage: Decimal(11.11)
        )

        // When
        let jsonData = try JSONEncoder().encode(holding)

        // Then
        XCTAssertGreaterThan(jsonData.count, 0)

        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["id"] as? String, "bitcoin")
        XCTAssertEqual(json?["symbol"] as? String, "BTC")
        XCTAssertEqual(json?["name"] as? String, "Bitcoin")
    }

    func testWidgetHoldingDecoding() throws {
        // Given - Create a WidgetHolding, encode it, then decode it
        // This tests the round-trip encoding/decoding
        let original = WidgetHolding(
            id: "ethereum",
            symbol: "ETH",
            name: "Ethereum",
            currentValue: Decimal(string: "30000.50")!,
            pnlAmount: Decimal(3000),
            pnlPercentage: Decimal(string: "11.11")!
        )

        // When - encode then decode
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(original)

        let decoder = JSONDecoder()
        let holding = try decoder.decode(WidgetHolding.self, from: jsonData)

        // Then
        XCTAssertEqual(holding.id, "ethereum")
        XCTAssertEqual(holding.symbol, "ETH")
        XCTAssertEqual(holding.name, "Ethereum")
        XCTAssertEqual(holding.currentValue, Decimal(string: "30000.50"))
        XCTAssertEqual(holding.pnlAmount, Decimal(3000))
    }

    func testEmptyPortfolioDataEncoding() throws {
        // Given
        let emptyData = WidgetPortfolioData(
            totalValue: 0,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: Date()
        )

        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(emptyData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedData = try decoder.decode(WidgetPortfolioData.self, from: jsonData)

        // Then
        XCTAssertEqual(decodedData.totalValue, 0)
        XCTAssertTrue(decodedData.holdings.isEmpty)
        XCTAssertTrue(decodedData.isEmpty)
    }

    func testDecimalPrecisionPreserved() throws {
        // Given - data with precise decimal values
        let data = WidgetPortfolioData(
            totalValue: Decimal(string: "123456.789012")!, // High precision
            unrealizedPnL: Decimal(string: "-9876.54321")!,
            realizedPnL: Decimal(string: "0.00000001")!, // Very small
            totalPnL: Decimal(string: "-9876.54320999")!,
            holdings: [],
            lastUpdated: Date()
        )

        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedData = try decoder.decode(WidgetPortfolioData.self, from: jsonData)

        // Then - precision should be preserved
        XCTAssertEqual(decodedData.totalValue, data.totalValue)
        XCTAssertEqual(decodedData.unrealizedPnL, data.unrealizedPnL)
        XCTAssertEqual(decodedData.realizedPnL, data.realizedPnL)
    }

    func testDatePrecisionPreserved() throws {
        // Given
        let now = Date()
        let data = WidgetPortfolioData(
            totalValue: 50000,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: now
        )

        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedData = try decoder.decode(WidgetPortfolioData.self, from: jsonData)

        // Then - dates should be within 1 second (ISO8601 has second precision)
        let timeDifference = abs(decodedData.lastUpdated.timeIntervalSince(now))
        XCTAssertLessThan(timeDifference, 1.0)
    }

    // MARK: - AppGroupStorage Unit Tests

    /// Note: Full integration tests require proper App Group entitlements
    /// These tests verify the storage can be instantiated

    func testAppGroupStorageSharedInstance() {
        // Then - shared instance should be available
        let storage = AppGroupStorage.shared
        XCTAssertNotNil(storage)
    }

    func testAppGroupIdentifierConstant() {
        // Then - identifier should match expected value
        XCTAssertEqual(AppGroupStorage.appGroupIdentifier, "group.com.bitpal.shared")
    }

    // MARK: - Edge Cases

    func testMaxHoldingsConstant() {
        // Then - max holdings should be 5
        XCTAssertEqual(WidgetPortfolioData.maxHoldings, 5)
    }

    func testWidgetPortfolioDataValidation() {
        // Valid data (5 or fewer holdings)
        let valid = WidgetPortfolioData(
            totalValue: 50000,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: Array(WidgetHolding.sampleHoldings.prefix(5)),
            lastUpdated: Date()
        )
        XCTAssertTrue(valid.isValid)

        // Still valid with fewer holdings
        let fewHoldings = WidgetPortfolioData(
            totalValue: 50000,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: Array(WidgetHolding.sampleHoldings.prefix(2)),
            lastUpdated: Date()
        )
        XCTAssertTrue(fewHoldings.isValid)

        // Empty is valid
        let empty = WidgetPortfolioData.empty
        XCTAssertTrue(empty.isValid)
    }

    func testSampleDataIsValid() {
        // All sample data should be valid
        XCTAssertTrue(WidgetPortfolioData.sample.isValid)
        XCTAssertTrue(WidgetPortfolioData.empty.isValid)
        XCTAssertTrue(WidgetPortfolioData.closedOnly.isValid)
        XCTAssertTrue(WidgetPortfolioData.stale.isValid)
        XCTAssertTrue(WidgetPortfolioData.singleHolding.isValid)
        XCTAssertTrue(WidgetPortfolioData.twoHoldings.isValid)
        XCTAssertTrue(WidgetPortfolioData.negative.isValid)
    }
}
