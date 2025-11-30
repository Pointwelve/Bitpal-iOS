//
//  ImportPreview.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-28.
//

import Foundation

/// Source file type for import
enum ImportSourceType: String {
    case json
    case csv
}

/// Preview of import data before user confirms
/// Per data-model.md: Ephemeral container holding parsed import data
struct ImportPreview {
    /// Source file type
    let sourceType: ImportSourceType

    /// Original file name for display
    let fileName: String

    /// Rows that passed validation
    let validRows: [ImportRow]

    /// Rows that failed validation with errors
    let invalidRows: [ImportRow]

    /// Total row count
    var totalRowCount: Int {
        validRows.count + invalidRows.count
    }

    /// Whether any valid rows exist to import
    var hasValidData: Bool {
        !validRows.isEmpty
    }
}

/// Single row from import file with validation status
/// Per data-model.md: Contains parsed values and validation errors
struct ImportRow: Identifiable {
    let id = UUID()

    /// Row number in source file (1-based for display)
    let rowNumber: Int

    /// Parsed values
    let coinId: String
    let type: TransactionType?
    let amount: Decimal?
    let pricePerCoin: Decimal?
    let date: Date?
    let notes: String?

    /// Validation errors for this row
    let errors: [String]

    /// Whether row is valid for import
    var isValid: Bool {
        errors.isEmpty && type != nil && amount != nil && pricePerCoin != nil && date != nil && !coinId.isEmpty
    }

    /// Convert to Transaction if valid
    func toTransaction() -> Transaction? {
        guard isValid,
              let type = type,
              let amount = amount,
              let pricePerCoin = pricePerCoin,
              let date = date else {
            return nil
        }

        return Transaction(
            id: UUID(),
            coinId: coinId,
            type: type,
            amount: amount,
            pricePerCoin: pricePerCoin,
            date: date,
            notes: notes
        )
    }
}
