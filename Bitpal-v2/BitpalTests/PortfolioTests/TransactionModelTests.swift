//
//  TransactionModelTests.swift
//  BitpalTests
//
//  Created by Claude Code on 2025-11-21.
//

import XCTest
import SwiftData
@testable import Bitpal

/// Unit tests for Transaction model creation and validation
/// Per Constitution Principle IV: Tests for data integrity
final class TransactionModelTests: XCTestCase {

    // MARK: - T017: Transaction Creation and Persistence

    func testTransactionCreation() {
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(string: "1.5")!,
            pricePerCoin: Decimal(40000),
            date: Date()
        )

        XCTAssertEqual(transaction.coinId, "bitcoin")
        XCTAssertEqual(transaction.type, .buy)
        XCTAssertEqual(transaction.amount, Decimal(string: "1.5")!)
        XCTAssertEqual(transaction.pricePerCoin, Decimal(40000))
        XCTAssertNotNil(transaction.id)
        XCTAssertNil(transaction.notes)
    }

    func testTransactionCreationWithNotes() {
        let transaction = Transaction(
            coinId: "ethereum",
            type: .sell,
            amount: Decimal(2),
            pricePerCoin: Decimal(3500),
            date: Date(),
            notes: "Profit taking"
        )

        XCTAssertEqual(transaction.coinId, "ethereum")
        XCTAssertEqual(transaction.type, .sell)
        XCTAssertEqual(transaction.notes, "Profit taking")
    }

    func testTransactionCreationWithCustomId() {
        let customId = UUID()
        let transaction = Transaction(
            id: customId,
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(1),
            pricePerCoin: Decimal(50000),
            date: Date()
        )

        XCTAssertEqual(transaction.id, customId)
    }

    func testTransactionTypeValues() {
        let buyTransaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(1),
            pricePerCoin: Decimal(40000),
            date: Date()
        )

        let sellTransaction = Transaction(
            coinId: "bitcoin",
            type: .sell,
            amount: Decimal(1),
            pricePerCoin: Decimal(50000),
            date: Date()
        )

        XCTAssertEqual(buyTransaction.type, .buy)
        XCTAssertEqual(sellTransaction.type, .sell)
    }

    // MARK: - T018: Validation Tests

    func testPositiveAmountIsValid() {
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(string: "0.00000001")!, // 1 satoshi
            pricePerCoin: Decimal(50000),
            date: Date()
        )

        XCTAssertGreaterThan(transaction.amount, 0)
    }

    func testPositivePriceIsValid() {
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(1),
            pricePerCoin: Decimal(string: "0.01")!, // 1 cent
            date: Date()
        )

        XCTAssertGreaterThan(transaction.pricePerCoin, 0)
    }

    func testDateIsNotInFuture() {
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(1),
            pricePerCoin: Decimal(50000),
            date: Date() // Today
        )

        XCTAssertLessThanOrEqual(transaction.date, Date())
    }

    func testPastDateIsValid() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(1),
            pricePerCoin: Decimal(40000),
            date: pastDate
        )

        XCTAssertLessThan(transaction.date, Date())
    }

    // MARK: - Decimal Precision Tests

    func testDecimalPrecisionForAmount() {
        // Test high precision for fractional crypto amounts
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(string: "0.12345678")!,
            pricePerCoin: Decimal(50000),
            date: Date()
        )

        XCTAssertEqual(transaction.amount, Decimal(string: "0.12345678")!)
    }

    func testDecimalPrecisionForPrice() {
        // Test price with cents
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(1),
            pricePerCoin: Decimal(string: "50000.99")!,
            date: Date()
        )

        XCTAssertEqual(transaction.pricePerCoin, Decimal(string: "50000.99")!)
    }

    func testLargeAmounts() {
        // Test handling of large cryptocurrency amounts
        let transaction = Transaction(
            coinId: "dogecoin",
            type: .buy,
            amount: Decimal(1000000), // 1 million coins
            pricePerCoin: Decimal(string: "0.10")!,
            date: Date()
        )

        XCTAssertEqual(transaction.amount, Decimal(1000000))
    }

    func testLargePrices() {
        // Test handling of high price values
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(1),
            pricePerCoin: Decimal(1000000), // $1M per coin
            date: Date()
        )

        XCTAssertEqual(transaction.pricePerCoin, Decimal(1000000))
    }

    // MARK: - Edge Cases

    func testTransactionWithVerySmallAmount() {
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(sign: .plus, exponent: -8, significand: 1), // 0.00000001
            pricePerCoin: Decimal(50000),
            date: Date()
        )

        XCTAssertGreaterThan(transaction.amount, 0)
    }

    func testTransactionTotalCostCalculation() {
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(string: "1.5")!,
            pricePerCoin: Decimal(40000),
            date: Date()
        )

        let totalCost = transaction.amount * transaction.pricePerCoin
        XCTAssertEqual(totalCost, Decimal(60000))
    }
}
