//
//  ChartDataParsingTests.swift
//  BitpalTests
//
//  Created by Bitpal Development on 12/1/25.
//

import XCTest
@testable import Bitpal

/// Tests for chart data parsing from CoinGecko API responses
final class ChartDataParsingTests: XCTestCase {

    // MARK: - ChartDataPoint Tests

    func testChartDataPointFromValidArray() {
        // Given: Valid API array [timestamp_ms, price]
        let apiArray: [Double] = [1701388800000, 42000.50]

        // When: Creating ChartDataPoint
        let dataPoint = ChartDataPoint(from: apiArray)

        // Then: Should parse correctly
        XCTAssertNotNil(dataPoint)
        XCTAssertEqual(dataPoint?.price, Decimal(42000.50))

        // Verify timestamp (December 1, 2023 00:00:00 UTC)
        let expectedDate = Date(timeIntervalSince1970: 1701388800)
        XCTAssertEqual(dataPoint?.timestamp, expectedDate)
    }

    func testChartDataPointFromMalformedArray() {
        // Given: Array with only one element
        let malformedArray: [Double] = [1701388800000]

        // When: Creating ChartDataPoint
        let dataPoint = ChartDataPoint(from: malformedArray)

        // Then: Should return nil
        XCTAssertNil(dataPoint)
    }

    func testChartDataPointFromEmptyArray() {
        // Given: Empty array
        let emptyArray: [Double] = []

        // When: Creating ChartDataPoint
        let dataPoint = ChartDataPoint(from: emptyArray)

        // Then: Should return nil
        XCTAssertNil(dataPoint)
    }

    func testChartDataPointDecimalAccuracy() {
        // Given: Price with many decimal places
        let apiArray: [Double] = [1701388800000, 0.00000123456789]

        // When: Creating ChartDataPoint
        let dataPoint = ChartDataPoint(from: apiArray)

        // Then: Should preserve decimal accuracy
        XCTAssertNotNil(dataPoint)
        XCTAssertEqual(dataPoint?.price, Decimal(0.00000123456789))
    }

    func testArrayToChartDataPointsExtension() {
        // Given: API response array
        let apiData: [[Double]] = [
            [1701388800000, 42000.50],
            [1701392400000, 42150.75],
            [1701396000000, 41980.25]
        ]

        // When: Converting to ChartDataPoints
        let dataPoints = apiData.toChartDataPoints()

        // Then: Should convert all valid entries
        XCTAssertEqual(dataPoints.count, 3)
        XCTAssertEqual(dataPoints[0].price, Decimal(42000.50))
        XCTAssertEqual(dataPoints[1].price, Decimal(42150.75))
        XCTAssertEqual(dataPoints[2].price, Decimal(41980.25))
    }

    func testArrayToChartDataPointsFiltersMalformed() {
        // Given: API response with some malformed entries
        let apiData: [[Double]] = [
            [1701388800000, 42000.50],  // Valid
            [1701392400000],             // Invalid - only timestamp
            [1701396000000, 41980.25]   // Valid
        ]

        // When: Converting to ChartDataPoints
        let dataPoints = apiData.toChartDataPoints()

        // Then: Should only include valid entries
        XCTAssertEqual(dataPoints.count, 2)
    }

    // MARK: - CandleDataPoint Tests

    func testCandleDataPointFromValidArray() {
        // Given: Valid OHLC API array [timestamp_ms, open, high, low, close]
        let apiArray: [Double] = [1701388800000, 42000, 42500, 41800, 42300]

        // When: Creating CandleDataPoint
        let candle = CandleDataPoint(from: apiArray)

        // Then: Should parse correctly
        XCTAssertNotNil(candle)
        XCTAssertEqual(candle?.open, Decimal(42000))
        XCTAssertEqual(candle?.high, Decimal(42500))
        XCTAssertEqual(candle?.low, Decimal(41800))
        XCTAssertEqual(candle?.close, Decimal(42300))

        // Verify timestamp
        let expectedDate = Date(timeIntervalSince1970: 1701388800)
        XCTAssertEqual(candle?.timestamp, expectedDate)
    }

    func testCandleDataPointFromMalformedArray() {
        // Given: Array with only 4 elements (missing close)
        let malformedArray: [Double] = [1701388800000, 42000, 42500, 41800]

        // When: Creating CandleDataPoint
        let candle = CandleDataPoint(from: malformedArray)

        // Then: Should return nil
        XCTAssertNil(candle)
    }

    func testCandleDataPointFromEmptyArray() {
        // Given: Empty array
        let emptyArray: [Double] = []

        // When: Creating CandleDataPoint
        let candle = CandleDataPoint(from: emptyArray)

        // Then: Should return nil
        XCTAssertNil(candle)
    }

    func testCandleDataPointIsGreen() {
        // Given: Bullish candle (close > open)
        let apiArray: [Double] = [1701388800000, 42000, 42500, 41800, 42300]
        let candle = CandleDataPoint(from: apiArray)

        // Then: Should be green
        XCTAssertNotNil(candle)
        XCTAssertTrue(candle!.isGreen)
        XCTAssertFalse(candle!.isRed)
    }

    func testCandleDataPointIsRed() {
        // Given: Bearish candle (close < open)
        let apiArray: [Double] = [1701388800000, 42300, 42500, 41800, 42000]
        let candle = CandleDataPoint(from: apiArray)

        // Then: Should be red
        XCTAssertNotNil(candle)
        XCTAssertFalse(candle!.isGreen)
        XCTAssertTrue(candle!.isRed)
    }

    func testCandleDataPointNeutral() {
        // Given: Neutral candle (close == open)
        let apiArray: [Double] = [1701388800000, 42000, 42500, 41800, 42000]
        let candle = CandleDataPoint(from: apiArray)

        // Then: Should be green (convention: >= is green)
        XCTAssertNotNil(candle)
        XCTAssertTrue(candle!.isGreen)
        XCTAssertFalse(candle!.isRed)
    }

    func testCandleDataPointPriceChange() {
        // Given: Candle with known price change
        let apiArray: [Double] = [1701388800000, 40000, 42500, 39800, 42000]
        let candle = CandleDataPoint(from: apiArray)

        // Then: Price change should be correct
        XCTAssertNotNil(candle)
        XCTAssertEqual(candle!.priceChange, Decimal(2000)) // 42000 - 40000
    }

    func testCandleDataPointPercentageChange() {
        // Given: Candle with 5% gain
        let apiArray: [Double] = [1701388800000, 40000, 42500, 39800, 42000]
        let candle = CandleDataPoint(from: apiArray)

        // Then: Percentage change should be 5%
        XCTAssertNotNil(candle)
        XCTAssertEqual(candle!.percentageChange, Decimal(5)) // ((42000-40000)/40000) * 100 = 5
    }

    func testArrayToCandleDataPointsExtension() {
        // Given: OHLC API response array
        let apiData: [[Double]] = [
            [1701388800000, 42000, 42500, 41800, 42300],
            [1701392400000, 42300, 42600, 42100, 42450],
            [1701396000000, 42450, 42550, 42200, 42350]
        ]

        // When: Converting to CandleDataPoints
        let candles = apiData.toCandleDataPoints()

        // Then: Should convert all entries
        XCTAssertEqual(candles.count, 3)
        XCTAssertEqual(candles[0].open, Decimal(42000))
        XCTAssertEqual(candles[1].open, Decimal(42300))
        XCTAssertEqual(candles[2].open, Decimal(42450))
    }

    func testArrayToCandleDataPointsFiltersMalformed() {
        // Given: API response with malformed entries
        let apiData: [[Double]] = [
            [1701388800000, 42000, 42500, 41800, 42300],  // Valid
            [1701392400000, 42300, 42600],                // Invalid - missing fields
            [1701396000000, 42450, 42550, 42200, 42350]  // Valid
        ]

        // When: Converting to CandleDataPoints
        let candles = apiData.toCandleDataPoints()

        // Then: Should only include valid entries
        XCTAssertEqual(candles.count, 2)
    }

    // MARK: - Decimal Conversion Accuracy Tests

    func testDecimalAccuracyForSmallPrices() {
        // Given: Very small price (like some meme coins)
        let apiArray: [Double] = [1701388800000, 0.000000001234]

        // When: Creating ChartDataPoint
        let dataPoint = ChartDataPoint(from: apiArray)

        // Then: Should handle small values
        XCTAssertNotNil(dataPoint)
        // Note: Due to Double to Decimal conversion, exact precision may vary
        XCTAssertGreaterThan(dataPoint!.price, Decimal(0))
    }

    func testDecimalAccuracyForLargePrices() {
        // Given: Very large price (like BTC in future)
        let apiArray: [Double] = [1701388800000, 1000000.99]

        // When: Creating ChartDataPoint
        let dataPoint = ChartDataPoint(from: apiArray)

        // Then: Should handle large values
        XCTAssertNotNil(dataPoint)
        XCTAssertEqual(dataPoint?.price, Decimal(1000000.99))
    }
}
