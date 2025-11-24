//
//  PortfolioError.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import Foundation

/// Domain-specific errors for Portfolio feature
/// Per Constitution Principle IV: Typed errors for user-facing error handling
enum PortfolioError: LocalizedError {
    case coinNotFound(String)
    case insufficientBalance(coinId: String, owned: Decimal, attempted: Decimal)
    case invalidAmount
    case invalidPrice
    case futureDateNotAllowed
    case transactionNotFound(UUID)
    case saveFailed(Error)
    case deleteFailed(Error)
    case priceDataUnavailable

    var errorDescription: String? {
        switch self {
        case .coinNotFound(let coinId):
            return "Cryptocurrency '\(coinId)' not found"
        case .insufficientBalance(let coinId, let owned, let attempted):
            return "You only own \(owned) \(coinId). Cannot sell \(attempted)."
        case .invalidAmount:
            return "Amount must be greater than zero"
        case .invalidPrice:
            return "Price must be greater than zero"
        case .futureDateNotAllowed:
            return "Transaction date cannot be in the future"
        case .transactionNotFound(let id):
            return "Transaction \(id) not found"
        case .saveFailed(let error):
            return "Failed to save transaction: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete transaction: \(error.localizedDescription)"
        case .priceDataUnavailable:
            return "Price data is currently unavailable"
        }
    }
}
