//
//  ChartError.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// Error types for chart and coin detail feature operations
enum ChartError: LocalizedError {
    case invalidCoinId
    case invalidTimeRange
    case noDataAvailable
    case parsingFailed
    case networkError(Error)
    case rateLimitExceeded
    case cacheMiss

    var errorDescription: String? {
        switch self {
        case .invalidCoinId:
            return "Invalid cryptocurrency ID"
        case .invalidTimeRange:
            return "Invalid time range selected"
        case .noDataAvailable:
            return "No chart data available for this period"
        case .parsingFailed:
            return "Failed to parse chart data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .cacheMiss:
            return "Chart data not found in cache"
        }
    }
}
