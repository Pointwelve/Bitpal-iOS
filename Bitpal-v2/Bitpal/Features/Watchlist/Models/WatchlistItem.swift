//
//  WatchlistItem.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftData
import Foundation

/// Persistence model for user's watchlist
/// Per Constitution Principle III: Use Swift Data (NOT Core Data)
@Model
final class WatchlistItem {
    // MARK: - Properties

    /// Reference to Coin.id (unique constraint enforced)
    @Attribute(.unique) var coinId: String

    /// Timestamp when coin was added to watchlist
    var dateAdded: Date

    /// Manual sort position (reserved for future use, Phase 1 uses other sort methods)
    var sortOrder: Int

    // MARK: - Initialization

    init(coinId: String, dateAdded: Date = Date(), sortOrder: Int = 0) {
        self.coinId = coinId
        self.dateAdded = dateAdded
        self.sortOrder = sortOrder
    }
}
