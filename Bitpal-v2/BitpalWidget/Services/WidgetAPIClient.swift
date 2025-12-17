//
//  WidgetAPIClient.swift
//  BitpalWidget
//
//  Created by Claude Code via /speckit.implement on 2025-12-11.
//  Feature: 008-widget-background-refresh
//

import Foundation
import OSLog

/// Lightweight API client for widget to fetch fresh cryptocurrency prices.
/// Uses static methods - no state management needed for simple price fetching.
/// Per Constitution Principle I: Single batched request for all coins.
/// Per Constitution Principle III: No external dependencies (URLSession native).
enum WidgetAPIClient {
    // MARK: - Constants

    /// CoinGecko API base URL
    private static let baseURL = "https://api.coingecko.com/api/v3"

    /// Request timeout for widget (15 seconds to stay within WidgetKit budget)
    private static let timeoutInterval: TimeInterval = 15

    // MARK: - Public Methods

    /// Fetches current market prices for multiple coins in a single batched request.
    /// Per FR-003: Single batched API request for all held coins.
    /// - Parameter coinIds: Array of CoinGecko coin IDs (e.g., ["bitcoin", "ethereum"])
    /// - Returns: Dictionary mapping coinId to price data
    /// - Throws: WidgetAPIError if request fails
    static func fetchPrices(coinIds: [String]) async throws -> [String: CoinMarketData] {
        guard !coinIds.isEmpty else {
            Logger.widget.warning("fetchPrices called with empty coinIds array")
            return [:]
        }

        let ids = coinIds.joined(separator: ",")
        let urlString = "\(baseURL)/coins/markets?vs_currency=usd&ids=\(ids)&price_change_percentage=24h"

        guard let url = URL(string: urlString) else {
            Logger.widget.error("Invalid URL: \(urlString)")
            throw WidgetAPIError.invalidURL
        }

        Logger.widget.info("Fetching prices for \(coinIds.count) coins")

        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.widget.error("Response is not HTTPURLResponse")
                throw WidgetAPIError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                Logger.widget.error("HTTP error: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 429 {
                    throw WidgetAPIError.rateLimited
                }
                throw WidgetAPIError.httpError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            let marketData = try decoder.decode([CoinMarketData].self, from: data)

            // Convert array to dictionary keyed by coinId
            let priceDict = Dictionary(uniqueKeysWithValues: marketData.map { ($0.id, $0) })

            Logger.widget.info("Successfully fetched prices for \(priceDict.count) coins")
            return priceDict
        } catch let error as WidgetAPIError {
            throw error
        } catch {
            Logger.widget.error("Network error: \(error.localizedDescription)")
            throw WidgetAPIError.networkError(error)
        }
    }
}

// MARK: - Errors

/// Errors specific to widget API operations.
enum WidgetAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case rateLimited
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .rateLimited:
            return "API rate limit exceeded"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
