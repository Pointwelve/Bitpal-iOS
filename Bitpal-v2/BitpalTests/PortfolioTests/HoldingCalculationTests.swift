//
//  HoldingCalculationTests.swift
//  BitpalTests
//
//  Created by Claude Code on 2025-11-18.
//

import XCTest
@testable import Bitpal

/// Unit tests for holdings calculation logic
/// Per Constitution Principle IV: Tests written BEFORE implementation
final class HoldingCalculationTests: XCTestCase {

    // MARK: - Test Fixtures

    private func makeCoin(
        id: String = "bitcoin",
        symbol: String = "btc",
        name: String = "Bitcoin",
        currentPrice: Decimal = 50000
    ) -> Coin {
        Coin(
            id: id,
            symbol: symbol,
            name: name,
            currentPrice: currentPrice,
            priceChange24h: 0,
            lastUpdated: Date(),
            marketCap: nil
        )
    }

    private func makeTransaction(
        coinId: String = "bitcoin",
        type: TransactionType,
        amount: Decimal,
        pricePerCoin: Decimal
    ) -> Transaction {
        Transaction(
            coinId: coinId,
            type: type,
            amount: amount,
            pricePerCoin: pricePerCoin,
            date: Date()
        )
    }

    // MARK: - T009: Weighted Average Cost Calculation

    func testWeightedAverageCostCalculation() {
        // Buy 1 BTC at $40,000
        // Buy 1 BTC at $50,000
        // Avg cost should be $45,000
        let transactions = [
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 40000),
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 50000)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(holdings.count, 1)
        XCTAssertEqual(holdings[0].totalAmount, 2)
        XCTAssertEqual(holdings[0].avgCost, 45000)
    }

    // MARK: - T010: Profit Calculation

    func testProfitCalculation() {
        // Buy 2 BTC at $40,000 avg
        // Current price $50,000
        // Profit should be $20,000
        let transactions = [
            makeTransaction(type: .buy, amount: 2, pricePerCoin: 40000)
        ]

        let coin = makeCoin(currentPrice: 50000)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(holdings.count, 1)
        let holding = holdings[0]

        XCTAssertEqual(holding.currentValue, 100000) // 2 * 50000
        XCTAssertEqual(holding.profitLoss, 20000)    // 100000 - 80000
        XCTAssertGreaterThan(holding.profitLoss, 0)
    }

    // MARK: - T011: Loss Calculation

    func testLossCalculation() {
        // Buy 2 BTC at $50,000 avg
        // Current price $40,000
        // Loss should be $20,000
        let transactions = [
            makeTransaction(type: .buy, amount: 2, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 40000)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(holdings.count, 1)
        let holding = holdings[0]

        XCTAssertEqual(holding.currentValue, 80000)  // 2 * 40000
        XCTAssertEqual(holding.profitLoss, -20000)   // 80000 - 100000
        XCTAssertLessThan(holding.profitLoss, 0)
    }

    // MARK: - T012: P&L Percentage Accuracy

    func testProfitLossPercentageAccuracy() {
        // Buy 1 BTC at $40,000
        // Current price $50,000
        // P&L% should be 25%
        let transactions = [
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 40000)
        ]

        let coin = makeCoin(currentPrice: 50000)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        let holding = holdings[0]
        XCTAssertEqual(holding.profitLossPercentage, 25)
    }

    func testProfitLossPercentageNegative() {
        // Buy 1 BTC at $50,000
        // Current price $40,000
        // P&L% should be -20%
        let transactions = [
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 40000)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        let holding = holdings[0]
        XCTAssertEqual(holding.profitLossPercentage, -20)
    }

    // MARK: - T013: Mixed Buy/Sell Transactions

    func testMixedBuySellTransactions() {
        // Buy 3 ETH at $3,000
        // Sell 1 ETH
        // Remaining: 2 ETH, avg cost still $3,000
        let transactions = [
            makeTransaction(coinId: "ethereum", type: .buy, amount: 3, pricePerCoin: 3000),
            makeTransaction(coinId: "ethereum", type: .sell, amount: 1, pricePerCoin: 3500)
        ]

        let coin = makeCoin(id: "ethereum", symbol: "eth", name: "Ethereum", currentPrice: 2800)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["ethereum": coin]
        )

        XCTAssertEqual(holdings.count, 1)
        let holding = holdings[0]

        XCTAssertEqual(holding.totalAmount, 2)
        XCTAssertEqual(holding.avgCost, 3000)        // Avg cost unchanged by sells
        XCTAssertEqual(holding.currentValue, 5600)   // 2 * 2800
        XCTAssertEqual(holding.profitLoss, -400)     // 5600 - 6000
    }

    // MARK: - T014: Zero Holdings When All Sold

    func testZeroHoldingsWhenAllSold() {
        // Buy 1 BTC, sell 1 BTC
        // Holdings should be empty (nil)
        let transactions = [
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 40000),
            makeTransaction(type: .sell, amount: 1, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 50000)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(holdings.count, 0)
    }

    // MARK: - T015: Fractional Quantities

    func testFractionalQuantities() {
        // Buy 0.00000001 BTC (1 satoshi)
        let transactions = [
            makeTransaction(type: .buy, amount: Decimal(string: "0.00000001")!, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 50000)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(holdings.count, 1)
        XCTAssertEqual(holdings[0].totalAmount, Decimal(string: "0.00000001")!)
    }

    func testMultipleFractionalBuys() {
        // Buy 0.5 BTC at $40,000
        // Buy 1.5 BTC at $50,000
        // Total: 2 BTC, avg cost = (20000 + 75000) / 2 = $47,500
        let transactions = [
            makeTransaction(type: .buy, amount: Decimal(string: "0.5")!, pricePerCoin: 40000),
            makeTransaction(type: .buy, amount: Decimal(string: "1.5")!, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 50000)
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(holdings[0].totalAmount, 2)
        XCTAssertEqual(holdings[0].avgCost, 47500)
    }

    // MARK: - Additional Edge Cases

    func testMultipleCoins() {
        let transactions = [
            makeTransaction(coinId: "bitcoin", type: .buy, amount: 1, pricePerCoin: 40000),
            makeTransaction(coinId: "ethereum", type: .buy, amount: 10, pricePerCoin: 3000)
        ]

        let btc = makeCoin(id: "bitcoin", currentPrice: 50000)
        let eth = makeCoin(id: "ethereum", symbol: "eth", name: "Ethereum", currentPrice: 3500)

        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: ["bitcoin": btc, "ethereum": eth]
        )

        XCTAssertEqual(holdings.count, 2)
    }

    func testMissingPriceData() {
        // Transaction exists but no price data
        let transactions = [
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 40000)
        ]

        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: [:]  // No prices
        )

        XCTAssertEqual(holdings.count, 0)
    }

    func testZeroAvgCostPercentage() {
        // Edge case: avgCost is 0 (shouldn't happen but handle gracefully)
        let holding = Holding(
            id: "test",
            coin: makeCoin(),
            totalAmount: 1,
            avgCost: 0,
            currentValue: 50000
        )

        XCTAssertEqual(holding.profitLossPercentage, 0)
    }

    // MARK: - Partial Realized Gains Tests (Amendment 2025-12-05)

    func testPartialSaleRealizedGain() {
        // Buy 2 BTC @ $40,000, Sell 1 BTC @ $50,000
        // Expected partial realized gain: ($50,000 - $40,000) × 1 = $10,000
        let transactions = [
            makeTransaction(type: .buy, amount: 2, pricePerCoin: 40000),
            makeTransaction(type: .sell, amount: 1, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 55000)
        let partialGains = computePartialRealizedGains(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(partialGains, 10000, "Expected $10,000 realized gain from partial sale")
    }

    func testMultiplePartialSales() {
        // Buy 3 BTC @ $40,000
        // Sell 1 BTC @ $45,000 (+$5,000)
        // Sell 1 BTC @ $50,000 (+$10,000)
        // Expected partial realized gain: $15,000
        let transactions = [
            makeTransaction(type: .buy, amount: 3, pricePerCoin: 40000),
            makeTransaction(type: .sell, amount: 1, pricePerCoin: 45000),
            makeTransaction(type: .sell, amount: 1, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 55000)
        let partialGains = computePartialRealizedGains(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(partialGains, 15000, "Expected $15,000 realized gain from multiple partial sales")
    }

    func testPartialSaleWithLoss() {
        // Buy 2 BTC @ $50,000
        // Sell 1 BTC @ $40,000
        // Expected partial realized gain: ($40,000 - $50,000) × 1 = -$10,000
        let transactions = [
            makeTransaction(type: .buy, amount: 2, pricePerCoin: 50000),
            makeTransaction(type: .sell, amount: 1, pricePerCoin: 40000)
        ]

        let coin = makeCoin(currentPrice: 45000)
        let partialGains = computePartialRealizedGains(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(partialGains, -10000, "Expected -$10,000 realized loss from partial sale")
    }

    func testNoPartialGainsWhenNoSells() {
        // Buy 2 BTC @ $40,000, no sells
        // Expected partial realized gain: $0
        let transactions = [
            makeTransaction(type: .buy, amount: 2, pricePerCoin: 40000)
        ]

        let coin = makeCoin(currentPrice: 50000)
        let partialGains = computePartialRealizedGains(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(partialGains, 0, "Expected $0 realized gain when no sells")
    }

    func testNoPartialGainsForFullyClosed() {
        // Buy 1 BTC @ $40,000, Sell 1 BTC @ $50,000 (fully closed)
        // Expected partial realized gain: $0 (handled by ClosedPosition, not partial)
        let transactions = [
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 40000),
            makeTransaction(type: .sell, amount: 1, pricePerCoin: 50000)
        ]

        let coin = makeCoin(currentPrice: 55000)
        let partialGains = computePartialRealizedGains(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(partialGains, 0, "Expected $0 partial gains for fully closed position")
    }

    func testPartialGainsWithWeightedAvgCost() {
        // Buy 1 BTC @ $40,000
        // Buy 1 BTC @ $50,000
        // Avg cost = $45,000
        // Sell 1 BTC @ $55,000
        // Expected partial realized gain: ($55,000 - $45,000) × 1 = $10,000
        let transactions = [
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 40000),
            makeTransaction(type: .buy, amount: 1, pricePerCoin: 50000),
            makeTransaction(type: .sell, amount: 1, pricePerCoin: 55000)
        ]

        let coin = makeCoin(currentPrice: 60000)
        let partialGains = computePartialRealizedGains(
            transactions: transactions,
            currentPrices: ["bitcoin": coin]
        )

        XCTAssertEqual(partialGains, 10000, "Expected $10,000 realized gain using weighted avg cost")
    }

    func testPartialGainsAcrossMultipleCoins() {
        // BTC: Buy 2 @ $40,000, Sell 1 @ $50,000 (+$10,000)
        // ETH: Buy 10 @ $3,000, Sell 5 @ $4,000 (+$5,000)
        // Expected total partial realized gain: $15,000
        let transactions = [
            makeTransaction(coinId: "bitcoin", type: .buy, amount: 2, pricePerCoin: 40000),
            makeTransaction(coinId: "bitcoin", type: .sell, amount: 1, pricePerCoin: 50000),
            makeTransaction(coinId: "ethereum", type: .buy, amount: 10, pricePerCoin: 3000),
            makeTransaction(coinId: "ethereum", type: .sell, amount: 5, pricePerCoin: 4000)
        ]

        let btc = makeCoin(id: "bitcoin", currentPrice: 55000)
        let eth = makeCoin(id: "ethereum", symbol: "eth", name: "Ethereum", currentPrice: 3500)

        let partialGains = computePartialRealizedGains(
            transactions: transactions,
            currentPrices: ["bitcoin": btc, "ethereum": eth]
        )

        XCTAssertEqual(partialGains, 15000, "Expected $15,000 total realized gain across multiple coins")
    }
}
