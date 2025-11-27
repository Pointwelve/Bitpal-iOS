//
//  WidgetDataProviderTests.swift
//  BitpalTests
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import XCTest
@testable import Bitpal

/// Tests for WidgetDataTransformer prepareWidgetData function.
/// Per Constitution Principle IV: Widget calculations must be consistent with main app.
final class WidgetDataProviderTests: XCTestCase {

    // MARK: - Test Data

    private func createTestCoin(
        id: String,
        symbol: String,
        name: String,
        price: Decimal
    ) -> Coin {
        Coin(
            id: id,
            symbol: symbol,
            name: name,
            currentPrice: price,
            priceChange24h: 0,
            lastUpdated: Date(),
            marketCap: nil
        )
    }

    private func createTestHolding(
        coinId: String,
        symbol: String,
        name: String,
        totalAmount: Decimal,
        avgCost: Decimal,
        currentPrice: Decimal
    ) -> Holding {
        let coin = createTestCoin(id: coinId, symbol: symbol, name: name, price: currentPrice)
        let currentValue = totalAmount * currentPrice

        return Holding(
            id: coinId,
            coin: coin,
            totalAmount: totalAmount,
            avgCost: avgCost,
            currentValue: currentValue
        )
    }

    // MARK: - prepareWidgetData Tests

    func testPrepareWidgetDataWithEmptyHoldings() {
        // Given
        let summary = PortfolioSummary(
            totalValue: 0,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalOpenCost: 0,
            totalClosedCost: 0
        )
        let holdings: [Holding] = []

        // When
        let widgetData = prepareWidgetData(summary: summary, holdings: holdings)

        // Then
        XCTAssertEqual(widgetData.totalValue, 0)
        XCTAssertEqual(widgetData.unrealizedPnL, 0)
        XCTAssertEqual(widgetData.realizedPnL, 0)
        XCTAssertEqual(widgetData.totalPnL, 0)
        XCTAssertTrue(widgetData.holdings.isEmpty)
        XCTAssertTrue(widgetData.isEmpty)
    }

    func testPrepareWidgetDataWithSingleHolding() {
        // Given
        let holding = createTestHolding(
            coinId: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            totalAmount: 1.5,
            avgCost: 40000,
            currentPrice: 50000
        )

        let summary = PortfolioSummary(
            totalValue: 75000,
            unrealizedPnL: 15000,
            realizedPnL: 0,
            totalOpenCost: 60000,
            totalClosedCost: 0
        )

        // When
        let widgetData = prepareWidgetData(summary: summary, holdings: [holding])

        // Then
        XCTAssertEqual(widgetData.totalValue, 75000)
        XCTAssertEqual(widgetData.unrealizedPnL, 15000)
        XCTAssertEqual(widgetData.holdings.count, 1)
        XCTAssertFalse(widgetData.isEmpty)

        // Verify holding transformation
        let widgetHolding = widgetData.holdings[0]
        XCTAssertEqual(widgetHolding.id, "bitcoin")
        XCTAssertEqual(widgetHolding.symbol, "BTC") // Should be uppercased
        XCTAssertEqual(widgetHolding.name, "Bitcoin")
        XCTAssertEqual(widgetHolding.currentValue, 75000)
    }

    func testPrepareWidgetDataLimitsToFiveHoldings() {
        // Given - 7 holdings
        let holdings = [
            createTestHolding(coinId: "bitcoin", symbol: "btc", name: "Bitcoin", totalAmount: 1, avgCost: 40000, currentPrice: 50000),
            createTestHolding(coinId: "ethereum", symbol: "eth", name: "Ethereum", totalAmount: 10, avgCost: 2000, currentPrice: 3000),
            createTestHolding(coinId: "solana", symbol: "sol", name: "Solana", totalAmount: 100, avgCost: 50, currentPrice: 100),
            createTestHolding(coinId: "cardano", symbol: "ada", name: "Cardano", totalAmount: 1000, avgCost: 0.5, currentPrice: 0.8),
            createTestHolding(coinId: "polkadot", symbol: "dot", name: "Polkadot", totalAmount: 50, avgCost: 10, currentPrice: 15),
            createTestHolding(coinId: "dogecoin", symbol: "doge", name: "Dogecoin", totalAmount: 10000, avgCost: 0.05, currentPrice: 0.08),
            createTestHolding(coinId: "ripple", symbol: "xrp", name: "XRP", totalAmount: 1000, avgCost: 0.4, currentPrice: 0.6)
        ]

        let summary = PortfolioSummary(
            totalValue: 100000,
            unrealizedPnL: 20000,
            realizedPnL: 5000,
            totalOpenCost: 80000,
            totalClosedCost: 10000
        )

        // When
        let widgetData = prepareWidgetData(summary: summary, holdings: holdings)

        // Then
        XCTAssertEqual(widgetData.holdings.count, 5, "Should limit to 5 holdings")
        XCTAssertTrue(widgetData.isValid)
    }

    func testPrepareWidgetDataSortsByValueDescending() {
        // Given - Holdings in random order by value
        let holdings = [
            createTestHolding(coinId: "cardano", symbol: "ada", name: "Cardano", totalAmount: 100, avgCost: 0.5, currentPrice: 0.8), // Value: 80
            createTestHolding(coinId: "bitcoin", symbol: "btc", name: "Bitcoin", totalAmount: 1, avgCost: 40000, currentPrice: 50000), // Value: 50000
            createTestHolding(coinId: "ethereum", symbol: "eth", name: "Ethereum", totalAmount: 10, avgCost: 2000, currentPrice: 3000) // Value: 30000
        ]

        let summary = PortfolioSummary(
            totalValue: 80080,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalOpenCost: 80080,
            totalClosedCost: 0
        )

        // When
        let widgetData = prepareWidgetData(summary: summary, holdings: holdings)

        // Then - Should be sorted by value descending
        XCTAssertEqual(widgetData.holdings[0].id, "bitcoin") // Highest value
        XCTAssertEqual(widgetData.holdings[1].id, "ethereum")
        XCTAssertEqual(widgetData.holdings[2].id, "cardano") // Lowest value
    }

    func testPrepareWidgetDataPreservesPnLSign() {
        // Given - Holdings with negative P&L
        let holding = createTestHolding(
            coinId: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            totalAmount: 1,
            avgCost: 60000, // Bought at 60k
            currentPrice: 50000 // Now worth 50k (loss)
        )

        let summary = PortfolioSummary(
            totalValue: 50000,
            unrealizedPnL: -10000, // Loss of 10k
            realizedPnL: -5000,
            totalOpenCost: 60000,
            totalClosedCost: 5000
        )

        // When
        let widgetData = prepareWidgetData(summary: summary, holdings: [holding])

        // Then
        XCTAssertEqual(widgetData.unrealizedPnL, -10000)
        XCTAssertEqual(widgetData.realizedPnL, -5000)
        XCTAssertEqual(widgetData.totalPnL, -15000)

        let widgetHolding = widgetData.holdings[0]
        XCTAssertFalse(widgetHolding.isProfit, "Should indicate loss")
    }

    func testPrepareWidgetDataTimestamp() {
        // Given
        let summary = PortfolioSummary(
            totalValue: 0,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalOpenCost: 0,
            totalClosedCost: 0
        )

        // When
        let before = Date()
        let widgetData = prepareWidgetData(summary: summary, holdings: [])
        let after = Date()

        // Then
        XCTAssertGreaterThanOrEqual(widgetData.lastUpdated, before)
        XCTAssertLessThanOrEqual(widgetData.lastUpdated, after)
    }

    // MARK: - WidgetHolding Tests

    func testWidgetHoldingFromHolding() {
        // Given
        let holding = createTestHolding(
            coinId: "ethereum",
            symbol: "eth", // lowercase
            name: "Ethereum",
            totalAmount: 5,
            avgCost: 2000,
            currentPrice: 3000
        )

        // When - Create WidgetHolding using the same logic as prepareWidgetData
        let widgetHolding = WidgetHolding(
            id: holding.id,
            symbol: holding.coin.symbol.uppercased(),
            name: holding.coin.name,
            currentValue: holding.currentValue,
            pnlAmount: holding.profitLoss,
            pnlPercentage: holding.profitLossPercentage
        )

        // Then
        XCTAssertEqual(widgetHolding.id, "ethereum")
        XCTAssertEqual(widgetHolding.symbol, "ETH") // Should be uppercased
        XCTAssertEqual(widgetHolding.name, "Ethereum")
        XCTAssertEqual(widgetHolding.currentValue, 15000) // 5 * 3000
        XCTAssertTrue(widgetHolding.isProfit)
    }

    func testWidgetHoldingProfitFlag() {
        // Test positive P&L
        let profitHolding = WidgetHolding(
            id: "btc",
            symbol: "BTC",
            name: "Bitcoin",
            currentValue: 50000,
            pnlAmount: 10000,
            pnlPercentage: 25
        )
        XCTAssertTrue(profitHolding.isProfit)

        // Test negative P&L
        let lossHolding = WidgetHolding(
            id: "eth",
            symbol: "ETH",
            name: "Ethereum",
            currentValue: 30000,
            pnlAmount: -5000,
            pnlPercentage: -14.3
        )
        XCTAssertFalse(lossHolding.isProfit)

        // Test zero P&L (edge case - considered profit)
        let neutralHolding = WidgetHolding(
            id: "sol",
            symbol: "SOL",
            name: "Solana",
            currentValue: 10000,
            pnlAmount: 0,
            pnlPercentage: 0
        )
        XCTAssertTrue(neutralHolding.isProfit, "Zero P&L should be considered profit (green)")
    }

    // MARK: - WidgetPortfolioData Tests

    func testWidgetPortfolioDataIsEmpty() {
        // Empty: no holdings and zero value
        let empty = WidgetPortfolioData(
            totalValue: 0,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: Date()
        )
        XCTAssertTrue(empty.isEmpty)

        // Not empty: has holdings
        let hasHoldings = WidgetPortfolioData(
            totalValue: 50000,
            unrealizedPnL: 5000,
            realizedPnL: 0,
            totalPnL: 5000,
            holdings: [WidgetHolding.sampleHoldings[0]],
            lastUpdated: Date()
        )
        XCTAssertFalse(hasHoldings.isEmpty)

        // Not empty: has value but no holdings (edge case)
        let hasValueNoHoldings = WidgetPortfolioData(
            totalValue: 1000,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: Date()
        )
        XCTAssertFalse(hasValueNoHoldings.isEmpty)
    }

    func testWidgetPortfolioDataIsStale() {
        // Fresh data (just now)
        let fresh = WidgetPortfolioData(
            totalValue: 50000,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: Date()
        )
        XCTAssertFalse(fresh.isStale)

        // Stale data (2 hours ago)
        let stale = WidgetPortfolioData(
            totalValue: 50000,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: Date().addingTimeInterval(-7200) // 2 hours ago
        )
        XCTAssertTrue(stale.isStale)

        // Edge case: just under 60 minutes (should not be stale)
        // Using 59 minutes to avoid timing edge cases during test execution
        let justUnderOneHour = WidgetPortfolioData(
            totalValue: 50000,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: Date().addingTimeInterval(-3540) // 59 minutes
        )
        XCTAssertFalse(justUnderOneHour.isStale, "59 minutes should not be stale")
    }

    func testWidgetPortfolioDataMinutesSinceUpdate() {
        // Test 5 minutes ago
        let fiveMinAgo = WidgetPortfolioData(
            totalValue: 0,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: Date().addingTimeInterval(-300) // 5 min
        )
        XCTAssertEqual(fiveMinAgo.minutesSinceUpdate, 5)

        // Test just now
        let justNow = WidgetPortfolioData(
            totalValue: 0,
            unrealizedPnL: 0,
            realizedPnL: 0,
            totalPnL: 0,
            holdings: [],
            lastUpdated: Date()
        )
        XCTAssertEqual(justNow.minutesSinceUpdate, 0)
    }
}
