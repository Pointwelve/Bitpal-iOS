//
//  CoinDetailViewModelTests.swift
//  BitpalTests
//
//  Created by Bitpal Development on 12/7/25.
//

import XCTest
@testable import Bitpal

/// Tests for CoinDetailViewModel-related logic
/// Per Constitution Principle IV: Testing critical business logic
/// Note: Direct ViewModel tests may crash on simulator due to @Observable macro limitations.
/// These tests focus on the underlying logic used by the ViewModel.
final class CoinDetailViewModelTests: XCTestCase {

    // MARK: - Chart Type Preference Tests

    func testChartTypeSaveAndLoadPreference() {
        // Given: Set preference to candle
        ChartType.candle.saveAsPreference()

        // When: Load preference
        let loaded = ChartType.loadPreference()

        // Then: Should be candle
        XCTAssertEqual(loaded, .candle)

        // Cleanup: Reset to line
        ChartType.line.saveAsPreference()
    }

    func testChartTypeDefaultPreference() {
        // Given: Clear preference
        UserDefaults.standard.removeObject(forKey: "chartTypePreference")

        // When: Load preference
        let loaded = ChartType.loadPreference()

        // Then: Should default to line
        XCTAssertEqual(loaded, .line)
    }

    // MARK: - Available Time Ranges Tests

    func testLineChartAvailableRanges() {
        // Given
        let chartType = ChartType.line

        // When
        let ranges = chartType.availableRanges

        // Then: Line chart has 5 ranges
        XCTAssertEqual(ranges.count, 5)
        XCTAssertTrue(ranges.contains(.oneHour))
        XCTAssertTrue(ranges.contains(.oneDay))
        XCTAssertTrue(ranges.contains(.oneWeek))
        XCTAssertTrue(ranges.contains(.oneMonth))
        XCTAssertTrue(ranges.contains(.oneYear))
        XCTAssertFalse(ranges.contains(.fifteenMinutes))
        XCTAssertFalse(ranges.contains(.fourHours))
    }

    func testCandleChartAvailableRanges() {
        // Given
        let chartType = ChartType.candle

        // When
        let ranges = chartType.availableRanges

        // Then: Candle chart has 3 ranges (30M, 4H, 4D candle intervals)
        XCTAssertEqual(ranges.count, 3)
        XCTAssertFalse(ranges.contains(.fifteenMinutes))
        XCTAssertFalse(ranges.contains(.oneHour))
        XCTAssertFalse(ranges.contains(.fourHours))
        XCTAssertTrue(ranges.contains(.oneDay))       // 30M candles
        XCTAssertTrue(ranges.contains(.oneWeek))      // 4H candles
        XCTAssertTrue(ranges.contains(.sixMonths))    // 4D candles
        XCTAssertFalse(ranges.contains(.oneMonth))
        XCTAssertFalse(ranges.contains(.oneYear))
    }

    // MARK: - Range Availability Tests

    func testIsRangeAvailableForLine() {
        // Given
        let chartType = ChartType.line

        // Then
        XCTAssertFalse(chartType.isRangeAvailable(.fifteenMinutes))
        XCTAssertTrue(chartType.isRangeAvailable(.oneHour))
        XCTAssertFalse(chartType.isRangeAvailable(.fourHours))
        XCTAssertTrue(chartType.isRangeAvailable(.oneDay))
    }

    func testIsRangeAvailableForCandle() {
        // Given
        let chartType = ChartType.candle

        // Then: Only 3 ranges available for candle (30M, 4H, 4D candle intervals)
        XCTAssertFalse(chartType.isRangeAvailable(.fifteenMinutes))
        XCTAssertFalse(chartType.isRangeAvailable(.oneHour))
        XCTAssertFalse(chartType.isRangeAvailable(.fourHours))
        XCTAssertTrue(chartType.isRangeAvailable(.oneDay))       // 30M candles
        XCTAssertTrue(chartType.isRangeAvailable(.oneWeek))      // 4H candles
        XCTAssertFalse(chartType.isRangeAvailable(.oneMonth))    // Not available
        XCTAssertTrue(chartType.isRangeAvailable(.sixMonths))    // 4D candles
        XCTAssertFalse(chartType.isRangeAvailable(.oneYear))     // Not available
    }

    // MARK: - Closest Available Range Tests

    func testClosestAvailableRangeFor15MToLine() {
        // Given: Line chart (15M not available)
        let chartType = ChartType.line

        // When
        let closest = chartType.closestAvailableRange(to: .fifteenMinutes)

        // Then: Should map to 1H
        XCTAssertEqual(closest, .oneHour)
    }

    func testClosestAvailableRangeFor4HToLine() {
        // Given: Line chart (4H not available)
        let chartType = ChartType.line

        // When
        let closest = chartType.closestAvailableRange(to: .fourHours)

        // Then: Should map to 1H
        XCTAssertEqual(closest, .oneHour)
    }

    func testClosestAvailableRangeWhenAlreadyAvailable() {
        // Given: Line chart with 1D (available)
        let chartType = ChartType.line

        // When
        let closest = chartType.closestAvailableRange(to: .oneDay)

        // Then: Should return same range
        XCTAssertEqual(closest, .oneDay)
    }

    func testClosestAvailableRangeFor15MToCandle() {
        // Given: Candle chart (15M not available)
        let chartType = ChartType.candle

        // When
        let closest = chartType.closestAvailableRange(to: .fifteenMinutes)

        // Then: Should map to 1D (minimum for candle charts)
        XCTAssertEqual(closest, .oneDay)
    }

    func testClosestAvailableRangeFor1HToCandle() {
        // Given: Candle chart (1H not available)
        let chartType = ChartType.candle

        // When
        let closest = chartType.closestAvailableRange(to: .oneHour)

        // Then: Should map to 1D (minimum for candle charts)
        XCTAssertEqual(closest, .oneDay)
    }

    func testClosestAvailableRangeFor4HToCandle() {
        // Given: Candle chart (4H not available)
        let chartType = ChartType.candle

        // When
        let closest = chartType.closestAvailableRange(to: .fourHours)

        // Then: Should map to 1D (30M candles)
        XCTAssertEqual(closest, .oneDay)
    }

    func testClosestAvailableRangeFor1MToCandle() {
        // Given: Candle chart (1M not available, maps to 4D candles)
        let chartType = ChartType.candle

        // When
        let closest = chartType.closestAvailableRange(to: .oneMonth)

        // Then: Should map to sixMonths (4D candles)
        XCTAssertEqual(closest, .sixMonths)
    }

    func testClosestAvailableRangeFor1YToCandle() {
        // Given: Candle chart (1Y not available, maps to 4D candles)
        let chartType = ChartType.candle

        // When
        let closest = chartType.closestAvailableRange(to: .oneYear)

        // Then: Should map to sixMonths (4D candles)
        XCTAssertEqual(closest, .sixMonths)
    }

    func testClosestAvailableRangeFor6MToLine() {
        // Given: Line chart (6M not available)
        let chartType = ChartType.line

        // When
        let closest = chartType.closestAvailableRange(to: .sixMonths)

        // Then: Should map to 1Y
        XCTAssertEqual(closest, .oneYear)
    }

    // MARK: - Limited History Detection Tests

    func testLimitedHistoryDetectionWithFullData() {
        // Given: Data spanning full 1D range (24 hours)
        let now = Date()
        let data = (0..<24).map { hour in
            ChartDataPoint(
                timestamp: now.addingTimeInterval(Double(-24 + hour) * 3600),
                price: Decimal(45000 + Double(hour) * 10)
            )
        }

        // When: Check time span
        let oldest = data.first!.timestamp
        let newest = data.last!.timestamp
        let actualSpan = newest.timeIntervalSince(oldest)
        let expectedSpan = ChartTimeRange.oneDay.expectedTimeSpan

        // Then: ~23 hours is ~95% of expected, so should NOT be limited
        let isLimited = actualSpan < (expectedSpan * 0.8)
        XCTAssertFalse(isLimited)
    }

    func testLimitedHistoryDetectionWithPartialData() {
        // Given: Data spanning only 6 hours (for 1D range)
        let now = Date()
        let data = (0..<6).map { hour in
            ChartDataPoint(
                timestamp: now.addingTimeInterval(Double(-6 + hour) * 3600),
                price: Decimal(45000 + Double(hour) * 10)
            )
        }

        // When: Check time span
        let oldest = data.first!.timestamp
        let newest = data.last!.timestamp
        let actualSpan = newest.timeIntervalSince(oldest)
        let expectedSpan = ChartTimeRange.oneDay.expectedTimeSpan

        // Then: ~5 hours is ~21% of expected, should be limited
        let isLimited = actualSpan < (expectedSpan * 0.8)
        XCTAssertTrue(isLimited)
    }

    // MARK: - Time Range Expected Time Span Tests

    func testExpectedTimeSpanValues() {
        XCTAssertEqual(ChartTimeRange.fifteenMinutes.expectedTimeSpan, 15 * 60)
        XCTAssertEqual(ChartTimeRange.oneHour.expectedTimeSpan, 60 * 60)
        XCTAssertEqual(ChartTimeRange.fourHours.expectedTimeSpan, 4 * 60 * 60)
        XCTAssertEqual(ChartTimeRange.oneDay.expectedTimeSpan, 24 * 60 * 60)
        XCTAssertEqual(ChartTimeRange.oneWeek.expectedTimeSpan, 7 * 24 * 60 * 60)
        XCTAssertEqual(ChartTimeRange.oneMonth.expectedTimeSpan, 30 * 24 * 60 * 60)
        XCTAssertEqual(ChartTimeRange.sixMonths.expectedTimeSpan, 180 * 24 * 60 * 60)
        XCTAssertEqual(ChartTimeRange.oneYear.expectedTimeSpan, 365 * 24 * 60 * 60)
    }

    // MARK: - API Days Mapping Tests

    func testApiDaysMapping() {
        XCTAssertEqual(ChartTimeRange.fifteenMinutes.apiDays, "1")
        XCTAssertEqual(ChartTimeRange.oneHour.apiDays, "1")
        XCTAssertEqual(ChartTimeRange.fourHours.apiDays, "1")
        XCTAssertEqual(ChartTimeRange.oneDay.apiDays, "1")
        XCTAssertEqual(ChartTimeRange.oneWeek.apiDays, "7")
        XCTAssertEqual(ChartTimeRange.oneMonth.apiDays, "30")
        XCTAssertEqual(ChartTimeRange.sixMonths.apiDays, "180")
        XCTAssertEqual(ChartTimeRange.oneYear.apiDays, "365")
    }

    // MARK: - Cache TTL Tests

    func testCacheTTLValues() {
        // Short ranges have shorter TTL
        XCTAssertEqual(ChartTimeRange.fifteenMinutes.cacheTTL, 60)
        XCTAssertEqual(ChartTimeRange.oneHour.cacheTTL, 60)
        XCTAssertEqual(ChartTimeRange.fourHours.cacheTTL, 60)

        // Longer ranges have longer TTL
        XCTAssertEqual(ChartTimeRange.oneDay.cacheTTL, 300)
        XCTAssertEqual(ChartTimeRange.oneWeek.cacheTTL, 900)
        XCTAssertEqual(ChartTimeRange.oneMonth.cacheTTL, 1800)
        XCTAssertEqual(ChartTimeRange.sixMonths.cacheTTL, 3600)
        XCTAssertEqual(ChartTimeRange.oneYear.cacheTTL, 3600)
    }

    // MARK: - Max Data Points Tests

    func testMaxDataPointsValues() {
        XCTAssertEqual(ChartTimeRange.fifteenMinutes.maxDataPoints, 15)
        XCTAssertEqual(ChartTimeRange.oneHour.maxDataPoints, 60)
        XCTAssertEqual(ChartTimeRange.fourHours.maxDataPoints, 48)
        XCTAssertEqual(ChartTimeRange.oneDay.maxDataPoints, 96)
        XCTAssertEqual(ChartTimeRange.oneWeek.maxDataPoints, 42)
        XCTAssertEqual(ChartTimeRange.oneMonth.maxDataPoints, 30)
        XCTAssertEqual(ChartTimeRange.sixMonths.maxDataPoints, 45)
        XCTAssertEqual(ChartTimeRange.oneYear.maxDataPoints, 52)
    }

    func testCandleMaxDataPoints() {
        // Candle charts use consistent 42 candles for uniform visual density
        XCTAssertEqual(ChartTimeRange.candleMaxDataPoints, 42)
    }

    // MARK: - Candle Display Name Tests

    func testCandleDisplayNames() {
        // Candlestick charts show candle interval instead of time range
        XCTAssertEqual(ChartTimeRange.oneDay.candleDisplayName, "30M")
        XCTAssertEqual(ChartTimeRange.oneWeek.candleDisplayName, "4H")
        XCTAssertEqual(ChartTimeRange.sixMonths.candleDisplayName, "4D")
    }

    func testCandleDisplayNameFallback() {
        // Non-candle ranges fallback to displayName
        XCTAssertEqual(ChartTimeRange.fifteenMinutes.candleDisplayName, "15M")
        XCTAssertEqual(ChartTimeRange.oneHour.candleDisplayName, "1H")
        XCTAssertEqual(ChartTimeRange.oneMonth.candleDisplayName, "1M")
    }
}
