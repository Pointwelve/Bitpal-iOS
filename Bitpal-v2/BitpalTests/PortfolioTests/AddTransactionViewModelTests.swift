//
//  AddTransactionViewModelTests.swift
//  BitpalTests
//
//  Created by Claude Code on 2025-11-18.
//

import XCTest
import SwiftData
@testable import Bitpal

/// Unit tests for AddTransactionViewModel
/// Per Constitution Principle IV: Tests written BEFORE implementation
final class AddTransactionViewModelTests: XCTestCase {

    // MARK: - T019: Form Validation Tests

    func testValidTransactionPassesValidation() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = "bitcoin"
        viewModel.transactionType = .buy
        viewModel.amountString = "1.5"
        viewModel.priceString = "40000"
        viewModel.date = Date()

        XCTAssertTrue(viewModel.isValid)
        XCTAssertNil(viewModel.validationError)
    }

    func testInvalidAmountZero() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = "bitcoin"
        viewModel.transactionType = .buy
        viewModel.amountString = "0"
        viewModel.priceString = "40000"
        viewModel.date = Date()

        XCTAssertFalse(viewModel.isValid)
    }

    func testInvalidAmountNegative() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = "bitcoin"
        viewModel.transactionType = .buy
        viewModel.amountString = "-1"
        viewModel.priceString = "40000"
        viewModel.date = Date()

        XCTAssertFalse(viewModel.isValid)
    }

    func testInvalidPriceZero() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = "bitcoin"
        viewModel.transactionType = .buy
        viewModel.amountString = "1"
        viewModel.priceString = "0"
        viewModel.date = Date()

        XCTAssertFalse(viewModel.isValid)
    }

    func testInvalidFutureDate() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = "bitcoin"
        viewModel.transactionType = .buy
        viewModel.amountString = "1"
        viewModel.priceString = "40000"
        viewModel.date = Date().addingTimeInterval(86400) // Tomorrow

        XCTAssertFalse(viewModel.isValid)
    }

    func testInvalidNoCoinSelected() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = nil
        viewModel.transactionType = .buy
        viewModel.amountString = "1"
        viewModel.priceString = "40000"
        viewModel.date = Date()

        XCTAssertFalse(viewModel.isValid)
    }

    // MARK: - T020: Insufficient Balance Tests

    func testSellWithSufficientBalance() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = "bitcoin"
        viewModel.transactionType = .sell
        viewModel.amountString = "0.5"
        viewModel.priceString = "50000"
        viewModel.date = Date()
        viewModel.currentHoldingQuantity = 1.0  // Owns 1 BTC

        XCTAssertTrue(viewModel.isValid)
    }

    func testSellWithInsufficientBalance() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = "bitcoin"
        viewModel.transactionType = .sell
        viewModel.amountString = "2"
        viewModel.priceString = "50000"
        viewModel.date = Date()
        viewModel.currentHoldingQuantity = 1.0  // Only owns 1 BTC

        XCTAssertFalse(viewModel.isValid)
    }

    func testSellWithZeroHoldings() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCoinId = "bitcoin"
        viewModel.transactionType = .sell
        viewModel.amountString = "1"
        viewModel.priceString = "50000"
        viewModel.date = Date()
        viewModel.currentHoldingQuantity = 0  // Owns nothing

        XCTAssertFalse(viewModel.isValid)
    }

    // MARK: - Decimal Parsing Tests

    func testDecimalAmountParsing() {
        let viewModel = AddTransactionViewModel()
        viewModel.amountString = "0.00000001"

        XCTAssertEqual(viewModel.amount, Decimal(string: "0.00000001"))
    }

    func testInvalidAmountString() {
        let viewModel = AddTransactionViewModel()
        viewModel.amountString = "abc"

        XCTAssertNil(viewModel.amount)
    }
}
