//
//  HistoricalDataService.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class HistoricalDataService {
    static let shared = HistoricalDataService()
    
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var cachedData: [String: [ChartData]] = [:]
    
    private let apiClient = APIClient.shared
    private var modelContext: ModelContext?
    private let cache = MemoryCache<String, [ChartData]>()
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }
    
    // MARK: - Public API
    
    func loadHistoricalData(
        for currencyPair: CurrencyPair,
        period: ChartPeriod,
        forceRefresh: Bool = false
    ) async throws -> [ChartData] {
        let cacheKey = "\(currencyPair.id)-\(period.rawValue)"
        
        // Check cache first
        if !forceRefresh, let cachedData = cache.value(forKey: cacheKey) {
            return cachedData
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let data = try await fetchFromAPI(currencyPair: currencyPair, period: period)
            
            // Cache the data
            cache.setValue(data, forKey: cacheKey, expiry: .seconds(period.cacheExpirationSeconds))
            
            // Store in SwiftData for offline access
            await storeHistoricalData(data, for: currencyPair, period: period)
            
            return data
            
        } catch {
            errorMessage = error.localizedDescription
            
            // Try to load from local storage as fallback
            if let localData = await loadLocalHistoricalData(for: currencyPair, period: period) {
                return localData
            }
            
            throw error
        }
    }
    
    func preloadHistoricalData(for pairs: [CurrencyPair]) async {
        // Preload popular periods for better UX
        let popularPeriods: [ChartPeriod] = [.oneDay, .oneWeek, .oneMonth]
        
        await withTaskGroup(of: Void.self) { group in
            for pair in pairs {
                for period in popularPeriods {
                    group.addTask { [weak self] in
                        _ = try? await self?.loadHistoricalData(
                            for: pair,
                            period: period,
                            forceRefresh: false
                        )
                    }
                }
            }
        }
    }
    
    func clearCache() {
        cache.removeAll()
        cachedData.removeAll()
    }
    
    // MARK: - API Integration
    
    private func fetchFromAPI(
        currencyPair: CurrencyPair,
        period: ChartPeriod
    ) async throws -> [ChartData] {
        guard let baseSymbol = currencyPair.baseCurrency?.symbol,
              let quoteSymbol = currencyPair.quoteCurrency?.symbol else {
            throw HistoricalDataError.invalidCurrencyPair
        }
        
        print("🔄 Fetching historical data for \(baseSymbol)-\(quoteSymbol), period: \(period.rawValue)")
        
        let response: APIHistoricalDataResponse = try await apiClient.request(
            CryptoAPIEndpoint.priceHistorical(
                symbol: baseSymbol,
                currency: quoteSymbol,
                exchange: currencyPair.exchange?.id,
                period: period,
                limit: period.apiLimit
            )
        )
        
        print("✅ Received \(response.data.count) historical data points")
        if let firstPoint = response.data.first {
            print("📊 First data point: timestamp=\(firstPoint.timestamp), open=\(firstPoint.open), close=\(firstPoint.close)")
        }
        
        return response.data.compactMap { apiPoint in
            ChartData(
                id: "\(currencyPair.id)-\(apiPoint.time)",
                date: Date(timeIntervalSince1970: TimeInterval(apiPoint.time)),
                open: apiPoint.open,
                high: apiPoint.high,
                low: apiPoint.low,
                close: apiPoint.close,
                volume: apiPoint.volumeFrom
            )
        }
        .sorted { $0.date < $1.date }
    }
    
    // MARK: - Local Storage
    
    private func storeHistoricalData(
        _ data: [ChartData],
        for currencyPair: CurrencyPair,
        period: ChartPeriod
    ) async {
        guard let context = modelContext else { return }
        
        do {
            // Remove old data for this period
            let oldDataDescriptor = FetchDescriptor<HistoricalPrice>()
            
            let oldData = try context.fetch(oldDataDescriptor)
            // Filter and delete old data for this currency pair and period
            for old in oldData {
                if old.currencyPair?.id == currencyPair.id && old.period == period {
                    context.delete(old)
                }
            }
            
            // Insert new data
            for dataPoint in data {
                let historicalPrice = HistoricalPrice(
                    currencyPair: currencyPair,
                    timestamp: Int(dataPoint.date.timeIntervalSince1970),
                    open: dataPoint.open,
                    high: dataPoint.high,
                    low: dataPoint.low,
                    close: dataPoint.close,
                    volumeTo: dataPoint.volume,
                    period: period
                )
                
                context.insert(historicalPrice)
            }
            
            try context.save()
            
        } catch {
            print("Failed to store historical data: \(error)")
        }
    }
    
    private func loadLocalHistoricalData(
        for currencyPair: CurrencyPair,
        period: ChartPeriod
    ) async -> [ChartData]? {
        guard let context = modelContext else { return nil }
        
        do {
            let descriptor = FetchDescriptor<HistoricalPrice>(
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            
            let allPrices = try context.fetch(descriptor)
            // Filter for the specific currency pair and period
            let historicalPrices = allPrices.filter { price in
                price.currencyPair?.id == currencyPair.id && price.period == period
            }
            
            return historicalPrices.map { price in
                ChartData(
                    id: "\(currencyPair.id)-\(price.timestamp)",
                    date: Date(timeIntervalSince1970: TimeInterval(price.timestamp)),
                    open: price.open,
                    high: price.high,
                    low: price.low,
                    close: price.close,
                    volume: price.volumeTo
                )
            }
            
        } catch {
            print("Failed to load local historical data: \(error)")
            return nil
        }
    }
    
    // MARK: - Real-time Updates
    
    func updateRealtimeData(_ streamPrice: StreamPrice) {
        guard let price = streamPrice.price else { return }
        
        let cacheKey = "\(streamPrice.baseCurrency)-\(streamPrice.quoteCurrency)-\(streamPrice.exchange ?? "default")"
        
        // Update the latest data point in all cached periods
        for (key, data) in cachedData {
            if key.hasPrefix(cacheKey) {
                var updatedData = data
                if var lastPoint = updatedData.last {
                    // Update the last data point with current price
                    lastPoint = ChartData(
                        id: lastPoint.id,
                        date: Date(),
                        open: lastPoint.open,
                        high: max(lastPoint.high, price),
                        low: min(lastPoint.low, price),
                        close: price,
                        volume: streamPrice.volume24h ?? lastPoint.volume
                    )
                    updatedData[updatedData.count - 1] = lastPoint
                    cachedData[key] = updatedData
                }
            }
        }
    }
}

// MARK: - Extensions

extension ChartPeriod {
    var apiLimit: Int {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 60
        case .fifteenMinutes: return 96
        case .thirtyMinutes: return 96
        case .oneHour: return 60
        case .fourHours: return 48
        case .oneDay: return 24
        case .oneWeek: return 168
        case .oneMonth: return 30
        }
    }
    
    var cacheExpirationSeconds: Int {
        switch self {
        case .oneMinute: return 60 // 1 minute
        case .fiveMinutes: return 300 // 5 minutes
        case .fifteenMinutes: return 300 // 5 minutes
        case .thirtyMinutes: return 600 // 10 minutes
        case .oneHour: return 900 // 15 minutes
        case .fourHours: return 3600 // 1 hour
        case .oneDay: return 7200 // 2 hours
        case .oneWeek: return 14400 // 4 hours
        case .oneMonth: return 86400 // 24 hours
        }
    }
}

// MARK: - Memory Cache Implementation

final class MemoryCache<Key: Hashable, Value> {
    private struct CacheEntry {
        let value: Value
        let expirationDate: Date
    }
    
    private var cache: [Key: CacheEntry] = [:]
    private let queue = DispatchQueue(label: "MemoryCache", attributes: .concurrent)
    
    enum Expiry {
        case seconds(Int)
        case minutes(Int)
        case hours(Int)
        
        var timeInterval: TimeInterval {
            switch self {
            case .seconds(let seconds): return TimeInterval(seconds)
            case .minutes(let minutes): return TimeInterval(minutes * 60)
            case .hours(let hours): return TimeInterval(hours * 3600)
            }
        }
    }
    
    func setValue(_ value: Value, forKey key: Key, expiry: Expiry) {
        let expirationDate = Date().addingTimeInterval(expiry.timeInterval)
        let entry = CacheEntry(value: value, expirationDate: expirationDate)
        
        queue.async(flags: .barrier) {
            self.cache[key] = entry
        }
    }
    
    func value(forKey key: Key) -> Value? {
        return queue.sync {
            guard let entry = cache[key] else { return nil }
            
            if Date() > entry.expirationDate {
                cache.removeValue(forKey: key)
                return nil
            }
            
            return entry.value
        }
    }
    
    func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
    
    func removeAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

// MARK: - Error Handling

enum HistoricalDataError: LocalizedError {
    case invalidCurrencyPair
    case apiError(String)
    case networkError(Error)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidCurrencyPair:
            return "Invalid currency pair"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        case .parsingError:
            return "Failed to parse historical data"
        }
    }
}

// MARK: - API Models

struct HistoricalDataRequest: Codable {
    let symbol: String
    let currency: String
    let exchange: String?
    let period: ChartPeriod
    let limit: Int
}

// Use the APIHistoricalDataResponse from APIModels.swift for consistency
typealias HistoricalDataResponse = APIHistoricalDataResponse
typealias HistoricalDataPoint = CoinDeskHistoricalPoint