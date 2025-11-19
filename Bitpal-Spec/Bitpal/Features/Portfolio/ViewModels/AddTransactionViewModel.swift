//
//  AddTransactionViewModel.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import Foundation
import SwiftData
import Observation
import OSLog

/// ViewModel for transaction entry form
/// Per Constitution Principle III: Uses @Observable (NOT ObservableObject)
@Observable
final class AddTransactionViewModel {
    // MARK: - Form State

    var selectedCoinId: String?
    var selectedCoin: Coin?
    var transactionType: TransactionType = .buy
    var amountString: String = ""
    var priceString: String = ""
    var date: Date = Date()
    var notes: String = ""

    // MARK: - Validation State

    var isSaving: Bool = false

    /// Current holding quantity for sell validation (FR-003)
    var currentHoldingQuantity: Decimal = 0

    // MARK: - Dependencies

    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {
        // Explicit init for proper @Observable setup
    }

    deinit {
        // Explicit deinit for proper cleanup
        selectedCoin = nil
        modelContext = nil
    }

    // MARK: - Computed Properties

    /// Parse amount string to Decimal
    /// Per Constitution Principle IV: Uses Decimal for financial values
    var amount: Decimal? {
        guard !amountString.isEmpty else { return nil }
        return Decimal(string: amountString)
    }

    /// Parse price string to Decimal
    var price: Decimal? {
        guard !priceString.isEmpty else { return nil }
        return Decimal(string: priceString)
    }

    /// Total transaction value
    var totalValue: Decimal {
        guard let amount = amount, let price = price else { return 0 }
        return amount * price
    }

    /// Validation error (computed, no side effects)
    /// Returns the first validation error, or nil if valid
    var validationError: PortfolioError? {
        // Check coin selected
        guard selectedCoinId != nil else {
            return nil // No error shown until coin is selected
        }

        // Check amount
        guard let amount = amount, amount > 0 else {
            return .invalidAmount
        }

        // Check price
        guard let price = price, price > 0 else {
            return .invalidPrice
        }

        // Check date not in future (FR-002)
        guard date <= Date() else {
            return .futureDateNotAllowed
        }

        // Check sell doesn't exceed holdings (FR-003)
        if transactionType == .sell && amount > currentHoldingQuantity {
            return .insufficientBalance(
                coinId: selectedCoinId ?? "",
                owned: currentHoldingQuantity,
                attempted: amount
            )
        }

        return nil
    }

    /// Check if form is valid for submission (pure computed property)
    var isValid: Bool {
        selectedCoinId != nil && validationError == nil
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Actions

    /// Save transaction to Swift Data
    /// Per FR-004: Permanently store all transactions
    @MainActor
    func saveTransaction() async throws {
        guard isValid else {
            throw validationError ?? PortfolioError.invalidAmount
        }

        guard let coinId = selectedCoinId,
              let amount = amount,
              let price = price else {
            throw PortfolioError.invalidAmount
        }

        guard let context = modelContext else {
            throw PortfolioError.saveFailed(NSError(domain: "Bitpal", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model context not configured"]))
        }

        isSaving = true
        defer { isSaving = false }

        let transaction = Transaction(
            coinId: coinId,
            type: transactionType,
            amount: amount,
            pricePerCoin: price,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )

        context.insert(transaction)

        do {
            try context.save()
            Logger.persistence.info("Saved transaction: \(transaction.id)")
        } catch {
            Logger.persistence.error("Failed to save transaction: \(error)")
            throw PortfolioError.saveFailed(error)
        }
    }

    /// Reset form to initial state
    func reset() {
        selectedCoinId = nil
        selectedCoin = nil
        transactionType = .buy
        amountString = ""
        priceString = ""
        date = Date()
        notes = ""
        currentHoldingQuantity = 0
    }

    /// Prepopulate form for editing existing transaction
    func loadTransaction(_ transaction: Transaction) {
        selectedCoinId = transaction.coinId
        transactionType = transaction.type
        amountString = "\(transaction.amount)"
        priceString = "\(transaction.pricePerCoin)"
        date = transaction.date
        notes = transaction.notes ?? ""
    }
}
