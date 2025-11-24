//
//  SortOption.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation

/// Sort options for watchlist display
enum SortOption: String, CaseIterable {
    case name = "Name (A-Z)"
    case price = "Price (High-Low)"
    case change24h = "24h Change (Best-Worst)"
}
