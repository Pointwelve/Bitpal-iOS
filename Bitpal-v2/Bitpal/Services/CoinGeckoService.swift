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

    // MARK: - Chart Data Methods

    /// Fetch detailed coin information for coin detail screen
    /// Uses /coins/{id} endpoint with market_data enabled
    func fetchCoinDetail(id: String) async throws -> CoinDetail {
        await rateLimiter.waitForNextRequest()

        let urlString = "\(baseURL)/coins/\(id)?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false"

        guard let url = URL(string: urlString) else {
            throw ChartError.invalidCoinId
        }

        Logger.chart.info("CoinGeckoService: Fetching coin detail for \(id)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChartError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            throw ChartError.invalidCoinId
        case 429:
            throw ChartError.rateLimitExceeded
        default:
            Logger.chart.error("CoinGeckoService: API returned status \(httpResponse.statusCode)")
            throw ChartError.networkError(NSError(domain: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(CoinDetailAPIResponse.self, from: data)

        Logger.chart.info("CoinGeckoService: Fetched detail for \(apiResponse.name)")

        return apiResponse.toCoinDetail()
    }

    /// Fetch market chart data for line charts
    /// Uses /coins/{id}/market_chart endpoint
    func fetchMarketChart(coinId: String, days: String, currency: String = "usd") async throws -> [ChartDataPoint] {
        await rateLimiter.waitForNextRequest()

        let urlString = "\(baseURL)/coins/\(coinId)/market_chart?vs_currency=\(currency)&days=\(days)"

        guard let url = URL(string: urlString) else {
            throw ChartError.invalidCoinId
        }

        Logger.chart.info("CoinGeckoService: Fetching market chart for \(coinId), days=\(days)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChartError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            throw ChartError.invalidCoinId
        case 429:
            throw ChartError.rateLimitExceeded
        default:
            Logger.chart.error("CoinGeckoService: API returned status \(httpResponse.statusCode)")
            throw ChartError.networkError(NSError(domain: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
        }

        let decoder = JSONDecoder()
        let chartResponse = try decoder.decode(MarketChartResponse.self, from: data)

        let dataPoints = chartResponse.toChartDataPoints()

        guard !dataPoints.isEmpty else {
            throw ChartError.noDataAvailable
        }

        Logger.chart.info("CoinGeckoService: Fetched \(dataPoints.count) chart data points")

        return dataPoints
    }

    /// Fetch OHLC data for candlestick charts
    /// Uses /coins/{id}/ohlc endpoint
    func fetchOHLC(coinId: String, days: String, currency: String = "usd") async throws -> [CandleDataPoint] {
        await rateLimiter.waitForNextRequest()

        let urlString = "\(baseURL)/coins/\(coinId)/ohlc?vs_currency=\(currency)&days=\(days)"

        guard let url = URL(string: urlString) else {
            throw ChartError.invalidCoinId
        }

        Logger.chart.info("CoinGeckoService: Fetching OHLC for \(coinId), days=\(days)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChartError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            throw ChartError.invalidCoinId
        case 429:
            throw ChartError.rateLimitExceeded
        default:
            Logger.chart.error("CoinGeckoService: API returned status \(httpResponse.statusCode)")
            throw ChartError.networkError(NSError(domain: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
        }

        let decoder = JSONDecoder()
        let ohlcResponse = try decoder.decode(OHLCResponse.self, from: data)

        let candles = ohlcResponse.toCandles()

        guard !candles.isEmpty else {
            throw ChartError.noDataAvailable
        }

        Logger.chart.info("CoinGeckoService: Fetched \(candles.count) OHLC candles")

        return candles
    }
}
