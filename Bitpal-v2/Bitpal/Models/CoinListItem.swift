//
//  CoinListItem.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation

/// Lightweight coin metadata for search functionality
/// Used for autocomplete search without fetching full market data
struct CoinListItem: Codable, Identifiable {
    /// Unique CoinGecko identifier
    let id: String

    /// Ticker symbol (lowercase)
    let symbol: String

    /// Human-readable coin name
    let name: String
}
