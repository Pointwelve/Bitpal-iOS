//
//  Transaction.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import SwiftData
import Foundation

/// User's recorded buy/sell action
/// Per Constitution Principle IV: Uses Decimal for all financial values
/// Per Constitution Principle III: Swift Data @Model for persistence
@Model
final class Transaction {
    // MARK: - Properties

    var id: UUID
    var coinId: String              // Reference to Coin.id (CoinGecko ID)
    var type: TransactionType       // Buy or Sell
    var amount: Decimal             // Quantity of coins
    var pricePerCoin: Decimal       // USD price at transaction time
    var date: Date                  // Transaction date
    var notes: String?              // Optional user notes

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        coinId: String,
        type: TransactionType,
        amount: Decimal,
        pricePerCoin: Decimal,
        date: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.coinId = coinId
        self.type = type
        self.amount = amount
        self.pricePerCoin = pricePerCoin
        self.date = date
        self.notes = notes
    }
}
