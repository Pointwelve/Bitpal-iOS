//
//  ImportError.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-28.
//

import Foundation

/// Import operation errors with localized descriptions
/// Per Constitution Principle IV: Clear error handling for data operations
enum ImportError: LocalizedError, Equatable {
    /// File is empty or contains no data
    case emptyFile

    /// File format is invalid (parse error)
    case invalidFormat(String)

    /// CSV missing required column
    case missingRequiredColumn(String)

    /// File could not be accessed
    case fileAccessDenied

    /// No valid rows after validation
    case noValidRows

    /// Decimal parsing failed
    case invalidDecimal(field: String, value: String)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty or contains no transactions."
        case .invalidFormat(let detail):
            return "Invalid file format: \(detail)"
        case .missingRequiredColumn(let column):
            return "Missing required column: \(column)"
        case .fileAccessDenied:
            return "Unable to access the file. Please try again."
        case .noValidRows:
            return "No valid transactions found in the file."
        case .invalidDecimal(let field, let value):
            return "Invalid number '\(value)' for \(field)"
        }
    }
}
