//
//  TransactionType.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import Foundation

/// Enumeration of transaction directions
/// Per Constitution Principle IV: Used for calculation logic differentiation
enum TransactionType: String, Codable, CaseIterable {
    case buy
    case sell

    /// Display name for UI presentation
    var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
}
