//
//  ServiceProtocols.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

// MARK: - Price Service Protocol

protocol PriceStreamServiceProtocol: AnyObject {
    var prices: [String: StreamPrice] { get }
    var isStreaming: Bool { get }
    var connectionState: WebSocketManager.ConnectionState { get }
    
    func setModelContext(_ context: ModelContext)
    func setAPIKey(_ key: String) async
    func startStreaming(for pairs: [CurrencyPair]) async
    func stopStreaming() async
    func subscribe(to pair: CurrencyPair) async
    func unsubscribe(from pair: CurrencyPair) async
    func updatePrice(_ streamPrice: StreamPrice)
    func fetchLatestPrices(for pairs: [CurrencyPair]) async throws
    func getCurrentPrice(for symbol: String) -> Double
}

// MARK: - Historical Data Service Protocol

protocol HistoricalDataServiceProtocol: AnyObject {
    func loadHistoricalData(
        for pair: CurrencyPair,
        period: ChartPeriod,
        forceRefresh: Bool
    ) async throws -> [ChartData]
    
    func getOHLCVData(
        for pair: CurrencyPair,
        period: ChartPeriod,
        limit: Int
    ) async throws -> [ChartData]
    
    func getCachedData(for pair: CurrencyPair, period: ChartPeriod) -> [ChartData]?
    func cacheData(_ data: [ChartData], for pair: CurrencyPair, period: ChartPeriod)
}


// MARK: - Currency Search Service Protocol

protocol CurrencySearchServiceProtocol: AnyObject {
    var availableCurrencies: [AvailableCurrency] { get }
    var searchResults: [AvailableCurrency] { get }
    var isLoading: Bool { get }
    
    func loadInitialData() async
    func searchCurrencies(_ query: String)
    func getTopCurrencies(limit: Int) -> [AvailableCurrency]
    func getTrendingCurrencies() async -> [AvailableCurrency]
    func getRecentlyAdded() -> [AvailableCurrency]
    func getAvailableExchanges(for symbol: String, quoteCurrency: String) async -> [Exchange]
}

// MARK: - Technical Analysis Service Protocol

protocol TechnicalAnalysisServiceProtocol: AnyObject {
    func calculateSMA(data: [ChartData], period: Int) -> [Double]
    func calculateEMA(data: [ChartData], period: Int) -> [Double]
    func calculateRSI(data: [ChartData], period: Int) -> [Double]
    func calculateMACD(data: [ChartData]) -> (macd: [Double], signal: [Double], histogram: [Double])
    func calculateBollingerBands(data: [ChartData], period: Int, standardDeviations: Double) -> (upper: [Double], middle: [Double], lower: [Double])
    func calculateVolatility(data: [ChartData], period: Int) -> Double
    func calculateSupport(data: [ChartData]) -> [Double]
    func calculateResistance(data: [ChartData]) -> [Double]
}

// MARK: - Portfolio Service Protocol

protocol PortfolioServiceProtocol: AnyObject {
    var portfolios: [Portfolio] { get }
    var defaultPortfolio: Portfolio? { get }
    var isLoading: Bool { get }
    
    func setModelContext(_ context: ModelContext)
    func loadPortfolios() async
    func createPortfolio(_ portfolio: Portfolio) async throws
    func updatePortfolio(_ portfolio: Portfolio) async throws
    func deletePortfolio(_ portfolio: Portfolio) async throws
    func setDefaultPortfolio(_ portfolio: Portfolio) async throws
    func calculateTotalValue() async -> Double
    func calculateDailyChange() async -> (amount: Double, percentage: Double)
}

// MARK: - Network Service Protocol

protocol NetworkServiceProtocol: AnyObject {
    var isConnected: Bool { get }
    var connectionType: ConnectionType { get }
    
    func request<T: Codable>(_ endpoint: any APIEndpoint) async throws -> T
    func buildRequest(endpoint: any APIEndpoint) throws -> URLRequest
}

// MARK: - Cache Service Protocol

protocol CacheServiceProtocol: AnyObject {
    func get<T>(_ key: String, type: T.Type) async -> T?
    func set<T>(_ key: String, value: T, ttl: TimeInterval?) async
    func remove(_ key: String) async
    func clear() async
    func clearExpired() async
}

// MARK: - Performance Monitor Protocol

protocol PerformanceMonitorProtocol: AnyObject {
    @MainActor func startOperation(_ name: String) -> String
    @MainActor func endOperation(_ id: String)
    @MainActor func logMemoryUsage()
    @MainActor func logNetworkRequest(_ request: URLRequest, duration: TimeInterval, success: Bool)
    @MainActor func getPerformanceMetrics() -> PerformanceMetrics
}

// MARK: - Error Recovery Protocol

protocol ErrorRecoveryProtocol: AnyObject {
    func canRecover(from error: Error) -> Bool
    func recover(from error: Error) async throws
    func fallbackStrategy(for error: Error) -> FallbackStrategy
}

// MARK: - Supporting Types

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

enum FallbackStrategy {
    case useCache
    case useSampleData
    case retry(after: TimeInterval)
    case showError
}

struct PerformanceMetrics {
    let averageResponseTime: TimeInterval
    let successRate: Double
    let memoryUsage: Int
    let cacheHitRate: Double
    let operationCounts: [String: Int]
}

// MARK: - Service Factory Protocol

protocol ServiceFactoryProtocol {
    func makePriceStreamService() -> PriceStreamServiceProtocol
    func makeHistoricalDataService() -> HistoricalDataServiceProtocol
    func makeCurrencySearchService() -> CurrencySearchServiceProtocol
    func makeTechnicalAnalysisService() -> TechnicalAnalysisServiceProtocol
    func makePortfolioService() -> PortfolioServiceProtocol
    func makeNetworkService() -> NetworkServiceProtocol
    func makeCacheService() -> CacheServiceProtocol
}