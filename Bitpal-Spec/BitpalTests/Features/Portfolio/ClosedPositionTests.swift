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
}
