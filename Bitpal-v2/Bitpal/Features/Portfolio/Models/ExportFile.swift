//
//  ExportFile.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-28.
//

import Foundation

/// Export file format with metadata for future compatibility
/// Per data-model.md: JSON wrapper containing transactions with metadata
struct ExportFile: Codable {
    /// Format version for migration support
    let version: String

    /// When export was created
    let exportDate: Date

    /// App version that created export
    let appVersion: String

    /// Array of transactions
    let transactions: [ExportTransaction]

    /// Current format version
    static let currentVersion = "1.0"
}

/// Transaction representation for JSON export
/// Per Constitution Principle IV: Uses String for Decimal fields to preserve precision
struct ExportTransaction: Codable {
    /// Original transaction UUID
    let id: UUID

    /// CoinGecko coin identifier
    let coinId: String

    /// Transaction type: "buy" or "sell"
    let type: String

    /// Quantity as string (preserves Decimal precision)
    let amount: String

    /// Price per coin as string (preserves Decimal precision)
    let pricePerCoin: String

    /// Transaction date (ISO 8601)
    let date: Date

    /// Optional user notes
    let notes: String?

    /// Initialize from Transaction model
    init(from transaction: Transaction) {
        self.id = transaction.id
        self.coinId = transaction.coinId
        self.type = transaction.type.rawValue
        self.amount = "\(transaction.amount)"
        self.pricePerCoin = "\(transaction.pricePerCoin)"
        self.date = transaction.date
        self.notes = transaction.notes
    }

    /// Initialize with explicit values (for testing)
    init(id: UUID, coinId: String, type: String, amount: String, pricePerCoin: String, date: Date, notes: String?) {
        self.id = id
        self.coinId = coinId
        self.type = type
        self.amount = amount
        self.pricePerCoin = pricePerCoin
        self.date = date
        self.notes = notes
    }
}
