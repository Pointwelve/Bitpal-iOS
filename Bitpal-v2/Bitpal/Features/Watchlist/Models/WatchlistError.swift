//
//  WatchlistError.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation

/// Error types for Watchlist feature operations
enum WatchlistError: LocalizedError {
    case invalidCoinId
    case coinAlreadyExists
    case coinNotFound
    case saveFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCoinId:
            return "Invalid cryptocurrency ID"
        case .coinAlreadyExists:
            return "This coin is already in your watchlist"
        case .coinNotFound:
            return "Cryptocurrency not found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
