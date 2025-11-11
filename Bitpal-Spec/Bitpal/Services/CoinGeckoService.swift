//
//  CoinGeckoService.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation
import OSLog

/// Service for interacting with CoinGecko API
/// Per Constitution Principle I: Batch API requests, respect rate limits, implement caching
final class CoinGeckoService {
    // MARK: - Singleton

    static let shared = CoinGeckoService()

    // MARK: - Properties

    private let baseURL = "https://api.coingecko.com/api/v3"
    private let rateLimiter = RateLimiter()
    private let session: URLSession

    // In-memory cache for coin list (7-day TTL)
    private var cachedCoinList: [CoinListItem]?
    private var coinListCacheTime: Date?
    private let coinListCacheTTL: TimeInterval = 60 * 60 * 24 * 7 // 7 days

    // In-memory cache for market data (30-second TTL)
    private var cachedMarketData: [String: Coin] = [:]
    private var marketDataCacheTime: Date?
    private let marketDataCacheTTL: TimeInterval = 30 // 30 seconds

    // MARK: - Initialization

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public Methods

    /// Fetch list of all available coins (cached for 7 days)
    /// Used for search autocomplete
    func fetchCoinList() async throws -> [CoinListItem] {
        // Check cache first
        if let cached = cachedCoinList,
           let cacheTime = coinListCacheTime,
           Date().timeIntervalSince(cacheTime) < coinListCacheTTL {
            Logger.api.debug("CoinGeckoService: Returning cached coin list")
            return cached
        }

        // Rate limit enforcement
        await rateLimiter.waitForNextRequest()

        let url = URL(string: "\(baseURL)/coins/list")!

        Logger.api.info("CoinGeckoService: Fetching coin list from API")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WatchlistError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            Logger.api.error("CoinGeckoService: API returned status \(httpResponse.statusCode)")
            throw WatchlistError.networkError(NSError(domain: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
        }

        let decoder = JSONDecoder()
        let coinList = try decoder.decode([CoinListItem].self, from: data)

        // Update cache
        cachedCoinList = coinList
        coinListCacheTime = Date()

        Logger.api.info("CoinGeckoService: Fetched \(coinList.count) coins, cached for 7 days")

        return coinList
    }

    /// Fetch market data for specific coins (batched, cached for 30 seconds)
    /// Per Constitution: MUST batch requests, NOT individual per coin
    func fetchMarketData(coinIds: [String]) async throws -> [String: Coin] {
        guard !coinIds.isEmpty else {
            Logger.api.warning("CoinGeckoService: fetchMarketData called with empty coinIds")
            return [:]
        }

        // Check cache first (only if all requested coins are cached and fresh)
        if let cacheTime = marketDataCacheTime,
           Date().timeIntervalSince(cacheTime) < marketDataCacheTTL {
            let allCached = coinIds.allSatisfy { cachedMarketData[$0] != nil }
            if allCached {
                Logger.api.debug("CoinGeckoService: Returning cached market data for \(coinIds.count) coins")
                return coinIds.reduce(into: [String: Coin]()) { result, id in
                    if let coin = cachedMarketData[id] {
                        result[id] = coin
                    }
                }
            }
        }

        // Rate limit enforcement
        await rateLimiter.waitForNextRequest()

        // Batch request (comma-separated coin IDs)
        let idsParam = coinIds.joined(separator: ",")
        let urlString = "\(baseURL)/coins/markets?vs_currency=usd&ids=\(idsParam)&price_change_percentage=24h"

        guard let url = URL(string: urlString) else {
            throw WatchlistError.networkError(NSError(domain: "Invalid URL", code: -1))
        }

        Logger.api.info("CoinGeckoService: Fetching market data for \(coinIds.count) coins")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WatchlistError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            Logger.api.error("CoinGeckoService: API returned status \(httpResponse.statusCode)")
            throw WatchlistError.networkError(NSError(domain: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let coins = try decoder.decode([Coin].self, from: data)

        // Convert to dictionary keyed by coinId
        let coinDict = coins.reduce(into: [String: Coin]()) { result, coin in
            result[coin.id] = coin
        }

        // Update cache
        for (id, coin) in coinDict {
            cachedMarketData[id] = coin
        }
        marketDataCacheTime = Date()

        Logger.api.info("CoinGeckoService: Fetched market data for \(coins.count) coins, cached for 30s")

        return coinDict
    }

    /// Invalidate market data cache (force fresh fetch on next request)
    func invalidateMarketDataCache() {
        cachedMarketData.removeAll()
        marketDataCacheTime = nil
        Logger.api.debug("CoinGeckoService: Market data cache invalidated")
    }

    /// Search coins using /coins/markets endpoint for relevance ranking (FR-015)
    /// Filters exchange-specific variants (FR-016) and provides native CoinGecko ranking
    func searchCoins(query: String, limit: Int = 50) async throws -> [CoinListItem] {
        guard !query.isEmpty else {
            return []
        }

        // Rate limit enforcement
        await rateLimiter.waitForNextRequest()

        // Use /coins/markets with search query for relevance ranking
        let urlString = "\(baseURL)/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=\(limit)&page=1&sparkline=false"

        guard let url = URL(string: urlString) else {
            throw WatchlistError.networkError(NSError(domain: "Invalid URL", code: -1))
        }

        Logger.api.info("CoinGeckoService: Searching coins for query '\(query)'")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WatchlistError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            Logger.api.error("CoinGeckoService: API returned status \(httpResponse.statusCode)")
            throw WatchlistError.networkError(NSError(domain: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let coins = try decoder.decode([Coin].self, from: data)

        // Convert to CoinListItem and filter by query
        let lowercasedQuery = query.lowercased()
        let results = coins
            .filter { coin in
                // Match query against name, symbol, or id
                coin.name.lowercased().contains(lowercasedQuery) ||
                coin.symbol.lowercased().contains(lowercasedQuery) ||
                coin.id.lowercased().contains(lowercasedQuery)
            }
            .filter { coin in
                // FR-016: Filter out exchange-specific variants (e.g., "Ethereum (Binance)")
                !coin.name.contains("(") && !coin.name.contains(")")
            }
            .map { coin in
                // Convert to lightweight CoinListItem
                CoinListItem(id: coin.id, symbol: coin.symbol, name: coin.name)
            }

        Logger.api.info("CoinGeckoService: Found \(results.count) search results for '\(query)'")

        return results
    }
}
