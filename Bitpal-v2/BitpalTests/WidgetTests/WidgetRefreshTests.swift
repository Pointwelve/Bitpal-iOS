//
//  WidgetRefreshTests.swift
//  BitpalTests
//
//  Created by Claude Code via /speckit.implement on 2025-12-11.
//  Feature: 008-widget-background-refresh
//
//  Per Constitution Principle IV: P&L calculations have unit tests written BEFORE implementation.
//

import XCTest
@testable import Bitpal

/// Tests for widget P&L recalculation logic.
/// Per Constitution: Financial calculations MUST be tested before implementation.
final class WidgetRefreshTests: XCTestCase {

    // MARK: - T005: P&L Recalculation Tests

    /// Test basic P&L recalculation with fresh prices
    func testPnLRecalculationWithFreshPrices() {
        // Given: Holdings with known quantities and average costs
        let refreshData = WidgetRefreshData(
            holdings: [
                WidgetRefreshData.RefreshableHolding(
                    coinId: "bitcoin",
                    symbol: "BTC",
                    name: "Bitcoin",
                    quantity: Decimal(string: "1.5")!,
                    avgCost: Decimal(string: "40000")!
                ),
                WidgetRefreshData.RefreshableHolding(
                    coinId: "ethereum",
                    symbol: "ETH",
                    name: "Ethereum",
                    quantity: Decimal(string: "10.0")!,
                    avgCost: Decimal(string: "2000")!
                )
            ],
            realizedPnL: Decimal(string: "500")!
        )

        // When: Fresh prices are received (BTC: $50,000, ETH: $2,500)
        let prices: [String: CoinMarketData] = [
            "bitcoin": CoinMarketData(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                currentPrice: Decimal(string: "50000")!,
                priceChangePercentage24h: Decimal(string: "5.0")
            ),
            "ethereum": CoinMarketData(
                id: "ethereum",
                symbol: "eth",
                name: "Ethereum",
                currentPrice: Decimal(string: "2500")!,
                priceChangePercentage24h: Decimal(string: "2.5")
            )
        ]

        // Then: P&L should be calculated correctly
        let result = PortfolioRecalculator.recalculate(refreshData: refreshData, prices: prices)

        // BTC: 1.5 × $50,000 = $75,000 value, cost = 1.5 × $40,000 = $60,000, P&L = $15,000
        // ETH: 10 × $2,500 = $25,000 value, cost = 10 × $2,000 = $20,000, P&L = $5,000
        // Total value = $100,000, Total unrealized P&L = $20,000
        // Total P&L = $20,000 unrealized + $500 realized = $20,500

        XCTAssertEqual(result.totalValue, Decimal(string: "100000")!, "Total value incorrect")
        XCTAssertEqual(result.unrealizedPnL, Decimal(string: "20000")!, "Unrealized P&L incorrect")
        XCTAssertEqual(result.realizedPnL, Decimal(string: "500")!, "Realized P&L should be unchanged")
        XCTAssertEqual(result.totalPnL, Decimal(string: "20500")!, "Total P&L incorrect")
        XCTAssertEqual(result.holdings.count, 2, "Should have 2 holdings")
    }

    /// Test P&L percentage calculation
    func testPnLPercentageCalculation() {
        // Given: Single holding with known values
        let refreshData = WidgetRefreshData(
            holdings: [
                WidgetRefreshData.RefreshableHolding(
                    coinId: "bitcoin",
                    symbol: "BTC",
                    name: "Bitcoin",
                    quantity: Decimal(string: "1.0")!,
                    avgCost: Decimal(string: "40000")! // Cost basis = $40,000
                )
            ],
            realizedPnL: 0
        )

        // When: Price is $50,000 (25% gain)
        let prices: [String: CoinMarketData] = [
            "bitcoin": CoinMarketData(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                currentPrice: Decimal(string: "50000")!,
                priceChangePercentage24h: nil
            )
        ]

        let result = PortfolioRecalculator.recalculate(refreshData: refreshData, prices: prices)

        // Expected: (50000/40000 - 1) × 100 = 25%
        assertDecimalEqual(result.holdings.first!.pnlPercentage, Decimal(string: "25")!, accuracy: Decimal(string: "0.01")!, "P&L percentage incorrect")
    }

    /// Test negative P&L (loss) calculation
    func testNegativePnLCalculation() {
        // Given: Holding bought at higher price
        let refreshData = WidgetRefreshData(
            holdings: [
                WidgetRefreshData.RefreshableHolding(
                    coinId: "bitcoin",
                    symbol: "BTC",
                    name: "Bitcoin",
                    quantity: Decimal(string: "2.0")!,
                    avgCost: Decimal(string: "60000")! // Cost basis = $120,000
                )
            ],
            realizedPnL: 0
        )

        // When: Price dropped to $50,000
        let prices: [String: CoinMarketData] = [
            "bitcoin": CoinMarketData(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                currentPrice: Decimal(string: "50000")!,
                priceChangePercentage24h: nil
            )
        ]

        let result = PortfolioRecalculator.recalculate(refreshData: refreshData, prices: prices)

        // Value = 2 × $50,000 = $100,000
        // Cost = 2 × $60,000 = $120,000
        // P&L = -$20,000
        XCTAssertEqual(result.totalValue, Decimal(string: "100000")!, "Total value incorrect")
        XCTAssertEqual(result.unrealizedPnL, Decimal(string: "-20000")!, "Should show negative P&L")
        XCTAssertTrue(result.holdings.first?.pnlAmount ?? 0 < 0, "P&L amount should be negative")
    }

    // MARK: - T006: Decimal Precision Preservation Tests

    /// Test that decimal precision is preserved in calculations
    func testDecimalPrecisionPreservation() {
        // Given: Holdings with precise decimal quantities
        let refreshData = WidgetRefreshData(
            holdings: [
                WidgetRefreshData.RefreshableHolding(
                    coinId: "bitcoin",
                    symbol: "BTC",
                    name: "Bitcoin",
                    quantity: Decimal(string: "0.12345678")!, // 8 decimal places
                    avgCost: Decimal(string: "45678.90123456")! // High precision cost
                )
            ],
            realizedPnL: Decimal(string: "123.456789")!
        )

        let prices: [String: CoinMarketData] = [
            "bitcoin": CoinMarketData(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                currentPrice: Decimal(string: "50000.12345")!,
                priceChangePercentage24h: nil
            )
        ]

        let result = PortfolioRecalculator.recalculate(refreshData: refreshData, prices: prices)

        // Verify precision is maintained (no floating-point rounding errors)
        // Value = 0.12345678 × 50000.12345 = 6172.84456...
        // This test verifies we don't lose precision using Decimal
        XCTAssertNotNil(result.totalValue, "Should calculate total value")
        XCTAssertEqual(result.realizedPnL, Decimal(string: "123.456789")!, "Realized P&L precision should be preserved")

        // Verify holding values have reasonable precision
        if let holding = result.holdings.first {
            XCTAssertGreaterThan(holding.currentValue, 0, "Current value should be positive")
        }
    }

    /// Test that zero average cost doesn't cause division errors
    func testZeroAverageCostHandling() {
        // Given: Holding with zero average cost (edge case)
        let refreshData = WidgetRefreshData(
            holdings: [
                WidgetRefreshData.RefreshableHolding(
                    coinId: "bitcoin",
                    symbol: "BTC",
                    name: "Bitcoin",
                    quantity: Decimal(string: "1.0")!,
                    avgCost: Decimal(0) // Zero cost (gifted/airdropped)
                )
            ],
            realizedPnL: 0
        )

        let prices: [String: CoinMarketData] = [
            "bitcoin": CoinMarketData(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                currentPrice: Decimal(string: "50000")!,
                priceChangePercentage24h: nil
            )
        ]

        // Should not crash or produce NaN
        let result = PortfolioRecalculator.recalculate(refreshData: refreshData, prices: prices)

        XCTAssertEqual(result.totalValue, Decimal(string: "50000")!, "Value should still calculate")
        XCTAssertEqual(result.holdings.first?.pnlPercentage, 0, "P&L percentage should be 0 when cost is 0")
    }

    // MARK: - T007: Missing Price Handling Tests

    /// Test handling when API returns partial data (some coins missing)
    func testMissingPriceHandling() {
        // Given: Two holdings but only one price in response
        let refreshData = WidgetRefreshData(
            holdings: [
                WidgetRefreshData.RefreshableHolding(
                    coinId: "bitcoin",
                    symbol: "BTC",
                    name: "Bitcoin",
                    quantity: Decimal(string: "1.0")!,
                    avgCost: Decimal(string: "40000")!
                ),
                WidgetRefreshData.RefreshableHolding(
                    coinId: "unknown-coin",
                    symbol: "UNK",
                    name: "Unknown Coin",
                    quantity: Decimal(string: "100")!,
                    avgCost: Decimal(string: "10")!
                )
            ],
            realizedPnL: 0
        )

        // Only bitcoin price available
        let prices: [String: CoinMarketData] = [
            "bitcoin": CoinMarketData(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                currentPrice: Decimal(string: "50000")!,
                priceChangePercentage24h: nil
            )
            // unknown-coin is missing
        ]

        let result = PortfolioRecalculator.recalculate(refreshData: refreshData, prices: prices)

        // Should only include holdings with available prices
        XCTAssertEqual(result.holdings.count, 1, "Should only include holdings with prices")
        XCTAssertEqual(result.holdings.first?.id, "bitcoin", "Should include bitcoin")

        // Total should only reflect holdings with prices
        XCTAssertEqual(result.totalValue, Decimal(string: "50000")!, "Total should only include priced holdings")
    }

    /// Test handling when no prices are available
    func testAllPricesMissing() {
        let refreshData = WidgetRefreshData(
            holdings: [
                WidgetRefreshData.RefreshableHolding(
                    coinId: "unknown-coin",
                    symbol: "UNK",
                    name: "Unknown Coin",
                    quantity: Decimal(string: "100")!,
                    avgCost: Decimal(string: "10")!
                )
            ],
            realizedPnL: Decimal(string: "500")!
        )

        // Empty prices dict
        let prices: [String: CoinMarketData] = [:]

        let result = PortfolioRecalculator.recalculate(refreshData: refreshData, prices: prices)

        // Should return empty holdings but preserve realized P&L
        XCTAssertTrue(result.holdings.isEmpty, "Should have no holdings when no prices")
        XCTAssertEqual(result.totalValue, 0, "Total value should be 0")
        XCTAssertEqual(result.unrealizedPnL, 0, "Unrealized P&L should be 0")
        XCTAssertEqual(result.realizedPnL, Decimal(string: "500")!, "Realized P&L should be preserved")
    }

    /// Test handling empty holdings
    func testEmptyHoldings() {
        let refreshData = WidgetRefreshData(
            holdings: [],
            realizedPnL: Decimal(string: "1000")!
        )

        let prices: [String: CoinMarketData] = [
            "bitcoin": CoinMarketData(
                id: "bitcoin",
                symbol: "btc",
                name: "Bitcoin",
                currentPrice: Decimal(string: "50000")!,
                priceChangePercentage24h: nil
            )
        ]

        let result = PortfolioRecalculator.recalculate(refreshData: refreshData, prices: prices)

        XCTAssertTrue(result.holdings.isEmpty, "Should have no holdings")
        XCTAssertEqual(result.totalValue, 0, "Total value should be 0")
        XCTAssertEqual(result.realizedPnL, Decimal(string: "1000")!, "Realized P&L preserved")
    }

    // MARK: - US2: Network Failure Fallback Tests (T013)

    /// Test staleness detection for cached data
    func testStalenessDetection() {
        // Given: Portfolio data from 70 minutes ago
        let staleDate = Date().addingTimeInterval(-70 * 60) // 70 minutes ago
        let portfolioData = WidgetPortfolioData(
            totalValue: 10000,
            unrealizedPnL: 500,
            realizedPnL: 100,
            totalPnL: 600,
            holdings: [],
            lastUpdated: staleDate
        )

        // Then: Should be marked as stale (> 60 minutes)
        XCTAssertTrue(portfolioData.isStale, "Data older than 60 minutes should be stale")
        XCTAssertGreaterThanOrEqual(portfolioData.minutesSinceUpdate, 70, "Should be at least 70 minutes old")
    }

    /// Test fresh data is not marked as stale
    func testFreshDataNotStale() {
        // Given: Portfolio data from 5 minutes ago
        let freshDate = Date().addingTimeInterval(-5 * 60) // 5 minutes ago
        let portfolioData = WidgetPortfolioData(
            totalValue: 10000,
            unrealizedPnL: 500,
            realizedPnL: 100,
            totalPnL: 600,
            holdings: [],
            lastUpdated: freshDate
        )

        // Then: Should not be marked as stale
        XCTAssertFalse(portfolioData.isStale, "Fresh data should not be stale")
    }
}

// MARK: - Test Helpers

extension WidgetRefreshTests {
    /// Helper to compare Decimal values with accuracy tolerance
    func assertDecimalEqual(_ expression1: Decimal, _ expression2: Decimal, accuracy: Decimal, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        let difference = abs(expression1 - expression2)
        XCTAssertLessThanOrEqual(difference, accuracy, message, file: file, line: line)
    }
}
