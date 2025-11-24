//
//  ClosedPositionTests.swift
//  BitpalTests
//
//  Created by Claude Code via /speckit.implement on 2025-11-23.
//  Test-driven development for Closed Positions feature (003-closed-positions)
//

import XCTest
import SwiftData
@testable import Bitpal

/// Unit tests for closed position calculation, cycle detection, and P&L computation
/// Per Constitution Principle IV: Tests written BEFORE implementation
final class ClosedPositionTests: XCTestCase {

    // MARK: - Test Data Fixtures

    /// Create mock Coin for testing (avoids API dependency)
    private func mockCoin(id: String = "bitcoin", symbol: String = "btc", name: String = "Bitcoin", price: Decimal = 50000) -> Coin {
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

    /// Create Transaction for testing
    private func createTransaction(
        coinId: String,
        type: TransactionType,
        amount: Decimal,
        pricePerCoin: Decimal,
        date: Date
    ) -> Transaction {
        Transaction(
            coinId: coinId,
            type: type,
            amount: amount,
            pricePerCoin: pricePerCoin,
            date: date,
            notes: nil
        )
    }

    // MARK: - Cycle Detection Tests

    /// T002: Test single buy/sell cycle detection
    /// Buy 1 BTC @ $40k, Sell 1 BTC @ $50k → expect 1 closed position with $10k profit
    func testSingleCycleDetection() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin", symbol: "btc", name: "Bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        let buy = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 40000,
            date: Date().addingTimeInterval(-86400) // 1 day ago
        )

        let sell = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 1.0,
            pricePerCoin: 50000,
            date: Date()
        )

        let transactions = [buy, sell]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        XCTAssertEqual(closedPositions.count, 1, "Should detect 1 closed position")

        guard let position = closedPositions.first else {
            XCTFail("No closed position found")
            return
        }

        XCTAssertEqual(position.coinId, "bitcoin")
        XCTAssertEqual(position.totalQuantity, 1.0)
        XCTAssertEqual(position.avgCostPrice, 40000)
        XCTAssertEqual(position.avgSalePrice, 50000)
        XCTAssertEqual(position.realizedPnL, 10000, "Expected $10k profit")
        XCTAssertEqual(position.realizedPnLPercentage, 25, accuracy: 0.01, "Expected 25% gain")
    }

    /// T003: Test multiple cycles for same coin
    /// Two buy/sell cycles → expect 2 separate ClosedPosition entries
    func testMultipleCyclesForSameCoin() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        // Cycle 1: Buy and sell
        let buy1 = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 40000,
            date: Date().addingTimeInterval(-172800) // 2 days ago
        )
        let sell1 = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 1.0,
            pricePerCoin: 50000,
            date: Date().addingTimeInterval(-86400) // 1 day ago
        )

        // Cycle 2: Buy again and sell again
        let buy2 = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 2.0,
            pricePerCoin: 30000,
            date: Date().addingTimeInterval(-43200) // 12 hours ago
        )
        let sell2 = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 2.0,
            pricePerCoin: 35000,
            date: Date()
        )

        let transactions = [buy1, sell1, buy2, sell2]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        XCTAssertEqual(closedPositions.count, 2, "Should detect 2 separate closed positions")

        // Verify sorted by close date (most recent first)
        XCTAssertTrue(closedPositions[0].closedDate > closedPositions[1].closedDate,
                      "Should be sorted by close date descending")
    }

    /// T004: Test fractional amounts within tolerance
    /// Buy 1.0 BTC, Sell 0.999999999 BTC → expect position closes (within 0.00000001 tolerance)
    func testFractionalAmountsWithinTolerance() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        let buy = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 40000,
            date: Date().addingTimeInterval(-86400)
        )

        let sell = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 0.999999999, // Within tolerance (0.000000001 difference)
            pricePerCoin: 50000,
            date: Date()
        )

        let transactions = [buy, sell]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        XCTAssertEqual(closedPositions.count, 1,
                       "Should detect closed position despite fractional difference within tolerance")
    }

    /// T005: Test fractional amounts outside tolerance
    /// Buy 1.0 BTC, Sell 0.99 BTC → expect position stays open
    func testFractionalAmountsOutsideTolerance() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        let buy = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 40000,
            date: Date().addingTimeInterval(-86400)
        )

        let sell = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 0.99, // Outside tolerance (0.01 difference)
            pricePerCoin: 50000,
            date: Date()
        )

        let transactions = [buy, sell]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        XCTAssertEqual(closedPositions.count, 0,
                       "Should NOT detect closed position when difference exceeds tolerance")
    }

    // MARK: - Weighted Average Tests

    /// T006: Test weighted average cost calculation
    /// Multiple buys at different prices → verify correct weighted average
    func testWeightedAverageCostCalculation() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        // Buy 0.5 BTC @ $40k = $20k cost
        let buy1 = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 0.5,
            pricePerCoin: 40000,
            date: Date().addingTimeInterval(-172800)
        )

        // Buy 0.5 BTC @ $50k = $25k cost
        let buy2 = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 0.5,
            pricePerCoin: 50000,
            date: Date().addingTimeInterval(-86400)
        )

        // Sell 1.0 BTC @ $60k
        let sell = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 1.0,
            pricePerCoin: 60000,
            date: Date()
        )

        let transactions = [buy1, buy2, sell]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        XCTAssertEqual(closedPositions.count, 1)

        guard let position = closedPositions.first else {
            XCTFail("No closed position found")
            return
        }

        // Weighted avg cost = (20k + 25k) / (0.5 + 0.5) = $45k
        XCTAssertEqual(position.avgCostPrice, 45000, "Expected weighted avg cost of $45k")
    }

    /// T007: Test weighted average sale calculation
    /// Multiple sells at different prices → verify correct weighted average
    func testWeightedAverageSaleCalculation() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        // Buy 1.0 BTC @ $40k
        let buy = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 40000,
            date: Date().addingTimeInterval(-172800)
        )

        // Sell 0.5 BTC @ $50k = $25k revenue
        let sell1 = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 0.5,
            pricePerCoin: 50000,
            date: Date().addingTimeInterval(-86400)
        )

        // Sell 0.5 BTC @ $60k = $30k revenue
        let sell2 = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 0.5,
            pricePerCoin: 60000,
            date: Date()
        )

        let transactions = [buy, sell1, sell2]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        XCTAssertEqual(closedPositions.count, 1)

        guard let position = closedPositions.first else {
            XCTFail("No closed position found")
            return
        }

        // Weighted avg sale = (25k + 30k) / (0.5 + 0.5) = $55k
        XCTAssertEqual(position.avgSalePrice, 55000, "Expected weighted avg sale price of $55k")
    }

    // MARK: - P&L Calculation Tests

    /// T008: Test profitable closed position
    /// Sale price > cost price → verify positive realized P&L
    func testProfitableClosedPosition() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        let buy = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 40000,
            date: Date().addingTimeInterval(-86400)
        )

        let sell = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 1.0,
            pricePerCoin: 50000,
            date: Date()
        )

        let transactions = [buy, sell]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        guard let position = closedPositions.first else {
            XCTFail("No closed position found")
            return
        }

        XCTAssertGreaterThan(position.realizedPnL, 0, "Should have positive P&L")
        XCTAssertEqual(position.realizedPnL, 10000, accuracy: 0.01)
        XCTAssertGreaterThan(position.realizedPnLPercentage, 0, "Should have positive % gain")
    }

    /// T009: Test loss closed position
    /// Sale price < cost price → verify negative realized P&L
    func testLossClosedPosition() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        let buy = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 50000,
            date: Date().addingTimeInterval(-86400)
        )

        let sell = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 1.0,
            pricePerCoin: 40000,
            date: Date()
        )

        let transactions = [buy, sell]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        guard let position = closedPositions.first else {
            XCTFail("No closed position found")
            return
        }

        XCTAssertLessThan(position.realizedPnL, 0, "Should have negative P&L")
        XCTAssertEqual(position.realizedPnL, -10000, accuracy: 0.01)
        XCTAssertLessThan(position.realizedPnLPercentage, 0, "Should have negative % loss")
    }

    /// T010: Test zero-cost position (gifted coins)
    /// Cost = 0, then sell → verify entire sale is profit
    func testZeroCostPosition() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        let gift = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 0, // Gifted (zero cost)
            date: Date().addingTimeInterval(-86400)
        )

        let sell = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 1.0,
            pricePerCoin: 50000,
            date: Date()
        )

        let transactions = [gift, sell]

        // Act
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        guard let position = closedPositions.first else {
            XCTFail("No closed position found")
            return
        }

        XCTAssertEqual(position.avgCostPrice, 0, "Cost should be zero for gifted coins")
        XCTAssertEqual(position.realizedPnL, 50000, "Entire sale revenue should be profit")
    }

    // MARK: - FR-016, FR-017: Cycle Isolation Tests

    /// T071: Test that closed cycle transactions are excluded from new holding calculations
    /// Scenario: Buy 1 BTC @ $40k, Sell 1 BTC @ $50k (close), Buy 1 BTC @ $60k (reopen)
    /// Expected: New holding shows avg cost = $60k (NOT blended with $40k from closed cycle)
    func testClosedCycleTransactionsExcludedFromNewHolding() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        // Cycle 1: Buy and sell (close position)
        let buy1 = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 40000,
            date: Date().addingTimeInterval(-172800)  // 2 days ago
        )

        let sell1 = createTransaction(
            coinId: "bitcoin",
            type: .sell,
            amount: 1.0,
            pricePerCoin: 50000,
            date: Date().addingTimeInterval(-86400)  // 1 day ago (closes Cycle 1)
        )

        // Cycle 2: Buy again (reopen position)
        let buy2 = createTransaction(
            coinId: "bitcoin",
            type: .buy,
            amount: 1.0,
            pricePerCoin: 60000,
            date: Date()  // Today (Cycle 2 starts)
        )

        let transactions = [buy1, sell1, buy2]

        // Act
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        XCTAssertEqual(holdings.count, 1, "Should have 1 open holding")

        guard let holding = holdings.first else {
            XCTFail("No holding found")
            return
        }

        XCTAssertEqual(holding.avgCost, 60000,
                       "Average cost should be $60k (from Cycle 2 only), not blended with Cycle 1's $40k")
        XCTAssertEqual(holding.totalAmount, 1.0,
                       "Total amount should be 1.0 BTC from Cycle 2")
    }

    /// T072: Test that multiple cycles are properly isolated
    /// Scenario: 3 complete buy/sell cycles, then 1 open position
    /// Expected: Open holding only uses transactions from the 4th cycle
    func testMultipleCyclesIsolation() {
        // Arrange
        let ethereum = mockCoin(id: "ethereum")
        let currentPrices = ["ethereum": ethereum]

        var transactions: [Transaction] = []

        // Cycle 1: Buy 10 ETH @ $2000, Sell 10 ETH @ $2500
        transactions.append(createTransaction(coinId: "ethereum", type: .buy, amount: 10.0, pricePerCoin: 2000, date: Date().addingTimeInterval(-432000)))  // 5 days ago
        transactions.append(createTransaction(coinId: "ethereum", type: .sell, amount: 10.0, pricePerCoin: 2500, date: Date().addingTimeInterval(-345600)))  // 4 days ago

        // Cycle 2: Buy 10 ETH @ $2200, Sell 10 ETH @ $2300
        transactions.append(createTransaction(coinId: "ethereum", type: .buy, amount: 10.0, pricePerCoin: 2200, date: Date().addingTimeInterval(-259200)))  // 3 days ago
        transactions.append(createTransaction(coinId: "ethereum", type: .sell, amount: 10.0, pricePerCoin: 2300, date: Date().addingTimeInterval(-172800)))  // 2 days ago

        // Cycle 3: Buy 10 ETH @ $2400, Sell 10 ETH @ $2600
        transactions.append(createTransaction(coinId: "ethereum", type: .buy, amount: 10.0, pricePerCoin: 2400, date: Date().addingTimeInterval(-86400)))  // 1 day ago
        transactions.append(createTransaction(coinId: "ethereum", type: .sell, amount: 10.0, pricePerCoin: 2600, date: Date().addingTimeInterval(-43200)))  // 12 hours ago

        // Cycle 4 (OPEN): Buy 10 ETH @ $3000
        transactions.append(createTransaction(coinId: "ethereum", type: .buy, amount: 10.0, pricePerCoin: 3000, date: Date()))  // Now

        // Act
        let holdings = computeHoldings(
            transactions: transactions,
            currentPrices: currentPrices
        )
        let closedPositions = computeClosedPositions(
            transactions: transactions,
            currentPrices: currentPrices
        )

        // Assert
        XCTAssertEqual(closedPositions.count, 3, "Should have 3 closed positions")
        XCTAssertEqual(holdings.count, 1, "Should have 1 open holding")

        guard let holding = holdings.first else {
            XCTFail("No holding found")
            return
        }

        XCTAssertEqual(holding.avgCost, 3000,
                       "Average cost should be $3000 (from Cycle 4 only), not blended with any previous cycles")
        XCTAssertEqual(holding.totalAmount, 10.0,
                       "Total amount should be 10.0 ETH from Cycle 4")
    }

    // MARK: - Grouping Tests (FR-019, FR-020, FR-022)

    /// T076: Test that closed positions are grouped by coin
    /// Scenario: Multiple cycles for Bitcoin and Ethereum
    /// Expected: 2 groups (Bitcoin, Ethereum), each with correct cycle counts
    func testClosedPositionsGroupedByCoin() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let ethereum = mockCoin(id: "ethereum")
        let currentPrices = ["bitcoin": bitcoin, "ethereum": ethereum]

        var transactions: [Transaction] = []

        // Bitcoin Cycle 1: Buy 1 BTC @ $40k, Sell 1 BTC @ $50k
        transactions.append(createTransaction(coinId: "bitcoin", type: .buy, amount: 1.0, pricePerCoin: 40000, date: Date().addingTimeInterval(-432000)))  // 5 days ago
        transactions.append(createTransaction(coinId: "bitcoin", type: .sell, amount: 1.0, pricePerCoin: 50000, date: Date().addingTimeInterval(-345600)))  // 4 days ago

        // Ethereum Cycle 1: Buy 10 ETH @ $2000, Sell 10 ETH @ $2500
        transactions.append(createTransaction(coinId: "ethereum", type: .buy, amount: 10.0, pricePerCoin: 2000, date: Date().addingTimeInterval(-259200)))  // 3 days ago
        transactions.append(createTransaction(coinId: "ethereum", type: .sell, amount: 10.0, pricePerCoin: 2500, date: Date().addingTimeInterval(-172800)))  // 2 days ago

        // Bitcoin Cycle 2: Buy 0.5 BTC @ $45k, Sell 0.5 BTC @ $48k
        transactions.append(createTransaction(coinId: "bitcoin", type: .buy, amount: 0.5, pricePerCoin: 45000, date: Date().addingTimeInterval(-86400)))  // 1 day ago
        transactions.append(createTransaction(coinId: "bitcoin", type: .sell, amount: 0.5, pricePerCoin: 48000, date: Date()))  // Now

        // Act
        let closedPositions = computeClosedPositions(transactions: transactions, currentPrices: currentPrices)
        let groups = computeClosedPositionGroups(closedPositions: closedPositions)

        // Assert
        XCTAssertEqual(groups.count, 2, "Should have 2 groups (Bitcoin, Ethereum)")

        // Find Bitcoin group
        guard let btcGroup = groups.first(where: { $0.coinId == "bitcoin" }) else {
            XCTFail("Bitcoin group not found")
            return
        }
        XCTAssertEqual(btcGroup.cycleCount, 2, "Bitcoin should have 2 cycles")
        XCTAssertEqual(btcGroup.closedPositions.count, 2, "Bitcoin group should contain 2 closed positions")

        // Find Ethereum group
        guard let ethGroup = groups.first(where: { $0.coinId == "ethereum" }) else {
            XCTFail("Ethereum group not found")
            return
        }
        XCTAssertEqual(ethGroup.cycleCount, 1, "Ethereum should have 1 cycle")
        XCTAssertEqual(ethGroup.closedPositions.count, 1, "Ethereum group should contain 1 closed position")
    }

    /// T077: Test aggregated metrics for grouped positions
    /// Scenario: Bitcoin with 2 profitable cycles
    /// Expected: Total P&L = sum of both cycles, percentage calculated correctly
    func testGroupAggregatedMetrics() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let currentPrices = ["bitcoin": bitcoin]

        var transactions: [Transaction] = []

        // Cycle 1: Buy 1 BTC @ $40k, Sell 1 BTC @ $50k (+$10k, +25%)
        transactions.append(createTransaction(coinId: "bitcoin", type: .buy, amount: 1.0, pricePerCoin: 40000, date: Date().addingTimeInterval(-259200)))  // 3 days ago
        transactions.append(createTransaction(coinId: "bitcoin", type: .sell, amount: 1.0, pricePerCoin: 50000, date: Date().addingTimeInterval(-172800)))  // 2 days ago

        // Cycle 2: Buy 2 BTC @ $45k, Sell 2 BTC @ $48k (+$6k, +6.67%)
        transactions.append(createTransaction(coinId: "bitcoin", type: .buy, amount: 2.0, pricePerCoin: 45000, date: Date().addingTimeInterval(-86400)))  // 1 day ago
        transactions.append(createTransaction(coinId: "bitcoin", type: .sell, amount: 2.0, pricePerCoin: 48000, date: Date()))  // Now

        // Act
        let closedPositions = computeClosedPositions(transactions: transactions, currentPrices: currentPrices)
        let groups = computeClosedPositionGroups(closedPositions: closedPositions)

        // Assert
        XCTAssertEqual(groups.count, 1, "Should have 1 group (Bitcoin)")

        guard let btcGroup = groups.first else {
            XCTFail("Bitcoin group not found")
            return
        }

        // Total P&L: $10k + $6k = $16k
        XCTAssertEqual(btcGroup.totalRealizedPnL, 16000, accuracy: 0.01, "Total P&L should be $16,000")

        // Weighted average percentage: (50k + 96k) / (40k + 90k) - 1 = 146k/130k - 1 ≈ 12.31%
        let expectedPercentage: Decimal = ((146000 / 130000) - 1) * 100
        XCTAssertEqual(btcGroup.totalRealizedPnLPercentage, expectedPercentage, accuracy: 0.1,
                       "Total P&L percentage should be weighted average of both cycles")

        XCTAssertEqual(btcGroup.cycleCount, 2, "Should have 2 cycles")
    }

    /// T078: Test that groups are sorted by most recent close date
    /// Scenario: Bitcoin closed 2 days ago, Ethereum closed 1 day ago, Cardano closed today
    /// Expected: Groups sorted [Cardano, Ethereum, Bitcoin] (most recent first)
    func testGroupsSortedByMostRecentCloseDate() {
        // Arrange
        let bitcoin = mockCoin(id: "bitcoin")
        let ethereum = mockCoin(id: "ethereum")
        let cardano = mockCoin(id: "cardano")
        let currentPrices = ["bitcoin": bitcoin, "ethereum": ethereum, "cardano": cardano]

        var transactions: [Transaction] = []

        // Bitcoin: Closed 2 days ago
        transactions.append(createTransaction(coinId: "bitcoin", type: .buy, amount: 1.0, pricePerCoin: 40000, date: Date().addingTimeInterval(-259200)))  // 3 days ago
        transactions.append(createTransaction(coinId: "bitcoin", type: .sell, amount: 1.0, pricePerCoin: 50000, date: Date().addingTimeInterval(-172800)))  // 2 days ago

        // Ethereum: Closed 1 day ago
        transactions.append(createTransaction(coinId: "ethereum", type: .buy, amount: 10.0, pricePerCoin: 2000, date: Date().addingTimeInterval(-172800)))  // 2 days ago
        transactions.append(createTransaction(coinId: "ethereum", type: .sell, amount: 10.0, pricePerCoin: 2500, date: Date().addingTimeInterval(-86400)))  // 1 day ago

        // Cardano: Closed today
        transactions.append(createTransaction(coinId: "cardano", type: .buy, amount: 1000.0, pricePerCoin: 0.5, date: Date().addingTimeInterval(-86400)))  // 1 day ago
        transactions.append(createTransaction(coinId: "cardano", type: .sell, amount: 1000.0, pricePerCoin: 0.6, date: Date()))  // Now

        // Act
        let closedPositions = computeClosedPositions(transactions: transactions, currentPrices: currentPrices)
        let groups = computeClosedPositionGroups(closedPositions: closedPositions)

        // Assert
        XCTAssertEqual(groups.count, 3, "Should have 3 groups")
        XCTAssertEqual(groups[0].coinId, "cardano", "First group should be Cardano (most recent)")
        XCTAssertEqual(groups[1].coinId, "ethereum", "Second group should be Ethereum")
        XCTAssertEqual(groups[2].coinId, "bitcoin", "Third group should be Bitcoin (least recent)")
    }
}
