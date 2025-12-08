//
//  ChartStatisticsTests.swift
//  BitpalTests
//
//  Created by Bitpal Development on 12/1/25.
//

import XCTest
@testable import Bitpal

/// Tests for chart statistics calculations
final class ChartStatisticsTests: XCTestCase {

    // MARK: - Line Data Statistics Tests

    func testStatisticsFromLineData() {
        // Given: Line chart data with known values
        let lineData = [
            ChartDataPoint(timestamp: Date(), price: Decimal(100)),
            ChartDataPoint(timestamp: Date().addingTimeInterval(3600), price: Decimal(105)),
            ChartDataPoint(timestamp: Date().addingTimeInterval(7200), price: Decimal(95)),
            ChartDataPoint(timestamp: Date().addingTimeInterval(10800), price: Decimal(110))
        ]

        // When: Calculating statistics
        let stats = ChartStatistics.from(lineData: lineData)

        // Then: Should calculate correctly
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.periodHigh, Decimal(110))
        XCTAssertEqual(stats?.periodLow, Decimal(95))
        XCTAssertEqual(stats?.startPrice, Decimal(100))
        XCTAssertEqual(stats?.endPrice, Decimal(110))
    }

    func testStatisticsFromEmptyLineData() {
        // Given: Empty array
        let lineData: [ChartDataPoint] = []

        // When: Calculating statistics
        let stats = ChartStatistics.from(lineData: lineData)

        // Then: Should return nil
        XCTAssertNil(stats)
    }

    func testStatisticsFromSingleLineDataPoint() {
        // Given: Single data point
        let lineData = [
            ChartDataPoint(timestamp: Date(), price: Decimal(100))
        ]

        // When: Calculating statistics
        let stats = ChartStatistics.from(lineData: lineData)

        // Then: Should handle single point (first == last)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.periodHigh, Decimal(100))
        XCTAssertEqual(stats?.periodLow, Decimal(100))
        XCTAssertEqual(stats?.startPrice, Decimal(100))
        XCTAssertEqual(stats?.endPrice, Decimal(100))
        XCTAssertEqual(stats?.priceChange, Decimal(0))
        XCTAssertEqual(stats?.percentageChange, Decimal(0))
    }

    // MARK: - Candle Data Statistics Tests

    func testStatisticsFromCandleData() {
        // Given: Candlestick data with known values
        let candleData = [
            CandleDataPoint(timestamp: Date(), open: Decimal(100), high: Decimal(108), low: Decimal(98), close: Decimal(105)),
            CandleDataPoint(timestamp: Date().addingTimeInterval(3600), open: Decimal(105), high: Decimal(115), low: Decimal(102), close: Decimal(110)),
            CandleDataPoint(timestamp: Date().addingTimeInterval(7200), open: Decimal(110), high: Decimal(112), low: Decimal(90), close: Decimal(95))
        ]

        // When: Calculating statistics
        let stats = ChartStatistics.from(candleData: candleData)

        // Then: Should use highs/lows from candles
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.periodHigh, Decimal(115)) // Highest high
        XCTAssertEqual(stats?.periodLow, Decimal(90))   // Lowest low
        XCTAssertEqual(stats?.startPrice, Decimal(100)) // First candle open
        XCTAssertEqual(stats?.endPrice, Decimal(95))    // Last candle close
    }

    func testStatisticsFromEmptyCandleData() {
        // Given: Empty array
        let candleData: [CandleDataPoint] = []

        // When: Calculating statistics
        let stats = ChartStatistics.from(candleData: candleData)

        // Then: Should return nil
        XCTAssertNil(stats)
    }

    // MARK: - Price Change Tests

    func testPositivePriceChange() {
        // Given: Statistics with price increase
        let stats = ChartStatistics(
            periodHigh: Decimal(120),
            periodLow: Decimal(90),
            startPrice: Decimal(100),
            endPrice: Decimal(110)
        )

        // Then: Should show positive change
        XCTAssertEqual(stats.priceChange, Decimal(10))
        XCTAssertEqual(stats.percentageChange, Decimal(10)) // 10%
        XCTAssertTrue(stats.isPositive)
    }

    func testNegativePriceChange() {
        // Given: Statistics with price decrease
        let stats = ChartStatistics(
            periodHigh: Decimal(120),
            periodLow: Decimal(80),
            startPrice: Decimal(100),
            endPrice: Decimal(90)
        )

        // Then: Should show negative change
        XCTAssertEqual(stats.priceChange, Decimal(-10))
        XCTAssertEqual(stats.percentageChange, Decimal(-10)) // -10%
        XCTAssertFalse(stats.isPositive)
    }

    func testZeroPriceChange() {
        // Given: Statistics with no change
        let stats = ChartStatistics(
            periodHigh: Decimal(110),
            periodLow: Decimal(90),
            startPrice: Decimal(100),
            endPrice: Decimal(100)
        )

        // Then: Should show zero change and be positive (convention)
        XCTAssertEqual(stats.priceChange, Decimal(0))
        XCTAssertEqual(stats.percentageChange, Decimal(0))
        XCTAssertTrue(stats.isPositive) // 0 is considered non-negative
    }

    func testZeroStartPrice() {
        // Given: Statistics with zero start price (edge case)
        let stats = ChartStatistics(
            periodHigh: Decimal(100),
            periodLow: Decimal(0),
            startPrice: Decimal(0),
            endPrice: Decimal(100)
        )

        // Then: Percentage change should be 0 (avoid division by zero)
        XCTAssertEqual(stats.percentageChange, Decimal(0))
    }

    // MARK: - Large Value Tests

    func testStatisticsWithLargeValues() {
        // Given: Large market cap style values
        let stats = ChartStatistics(
            periodHigh: Decimal(1_000_000_000),
            periodLow: Decimal(900_000_000),
            startPrice: Decimal(950_000_000),
            endPrice: Decimal(980_000_000)
        )

        // Then: Should handle large values correctly
        XCTAssertEqual(stats.priceChange, Decimal(30_000_000))
        XCTAssertTrue(stats.isPositive)
    }

    // MARK: - Small Value Tests

    func testStatisticsWithSmallValues() {
        // Given: Small meme coin style values
        // Use string-based Decimal initialization to avoid floating-point precision issues
        let stats = ChartStatistics(
            periodHigh: Decimal(string: "0.0001")!,
            periodLow: Decimal(string: "0.00005")!,
            startPrice: Decimal(string: "0.00008")!,
            endPrice: Decimal(string: "0.00009")!
        )

        // Then: Should handle small values correctly
        XCTAssertEqual(stats.priceChange, Decimal(string: "0.00001")!)
        XCTAssertTrue(stats.isPositive)
    }

    // MARK: - Percentage Calculation Tests

    func testPercentageCalculation50PercentGain() {
        // Given: 50% price increase
        let stats = ChartStatistics(
            periodHigh: Decimal(150),
            periodLow: Decimal(100),
            startPrice: Decimal(100),
            endPrice: Decimal(150)
        )

        // Then: Percentage should be 50
        XCTAssertEqual(stats.percentageChange, Decimal(50))
    }

    func testPercentageCalculation50PercentLoss() {
        // Given: 50% price decrease
        let stats = ChartStatistics(
            periodHigh: Decimal(100),
            periodLow: Decimal(50),
            startPrice: Decimal(100),
            endPrice: Decimal(50)
        )

        // Then: Percentage should be -50
        XCTAssertEqual(stats.percentageChange, Decimal(-50))
    }

    func testPercentageCalculation100PercentGain() {
        // Given: 100% price increase (doubled)
        let stats = ChartStatistics(
            periodHigh: Decimal(200),
            periodLow: Decimal(100),
            startPrice: Decimal(100),
            endPrice: Decimal(200)
        )

        // Then: Percentage should be 100
        XCTAssertEqual(stats.percentageChange, Decimal(100))
    }
}
