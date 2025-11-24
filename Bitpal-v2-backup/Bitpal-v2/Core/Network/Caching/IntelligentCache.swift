//
//  IntelligentCache.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import Combine

protocol CacheProtocol {
    associatedtype Key: Hashable
    associatedtype Value
    
    func get(_ key: Key) async -> Value?
    func set(_ key: Key, value: Value, ttl: TimeInterval?) async
    func remove(_ key: Key) async
    func clear() async
}

actor IntelligentCache<Key: Hashable, Value>: CacheProtocol {
    private struct CacheEntry {
        let value: Value
        let timestamp: Date
        let ttl: TimeInterval?
        let accessCount: Int
        let lastAccessed: Date
        
        var isExpired: Bool {
            guard let ttl = ttl else { return false }
            return Date().timeIntervalSince(timestamp) > ttl
        }
        
        func withAccess() -> CacheEntry {
            CacheEntry(
                value: value,
                timestamp: timestamp,
                ttl: ttl,
                accessCount: accessCount + 1,
                lastAccessed: Date()
            )
        }
    }
    
    private var storage: [Key: CacheEntry] = [:]
    private let maxSize: Int
    private let defaultTTL: TimeInterval
    private let cleanupInterval: TimeInterval
    private var cleanupTimer: Timer?
    
    // Cache statistics
    private var totalRequests: Int = 0
    private var cacheHits: Int = 0
    
    var hitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(cacheHits) / Double(totalRequests)
    }
    
    var currentSize: Int {
        return storage.count
    }
    
    init(
        maxSize: Int = 1000,
        defaultTTL: TimeInterval = 300, // 5 minutes
        cleanupInterval: TimeInterval = 60 // 1 minute
    ) {
        self.maxSize = maxSize
        self.defaultTTL = defaultTTL
        self.cleanupInterval = cleanupInterval
        
        startCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    func get(_ key: Key) async -> Value? {
        totalRequests += 1
        
        guard let entry = storage[key] else {
            return nil
        }
        
        if entry.isExpired {
            storage.removeValue(forKey: key)
            return nil
        }
        
        // Update access statistics
        storage[key] = entry.withAccess()
        cacheHits += 1
        
        return entry.value
    }
    
    func set(_ key: Key, value: Value, ttl: TimeInterval? = nil) async {
        let effectiveTTL = ttl ?? defaultTTL
        let entry = CacheEntry(
            value: value,
            timestamp: Date(),
            ttl: effectiveTTL,
            accessCount: 0,
            lastAccessed: Date()
        )
        
        storage[key] = entry
        
        // Evict if necessary
        if storage.count > maxSize {
            await evictLeastUsed()
        }
    }
    
    func remove(_ key: Key) async {
        storage.removeValue(forKey: key)
    }
    
    func clear() async {
        storage.removeAll()
        totalRequests = 0
        cacheHits = 0
    }
    
    // MARK: - Cache Management
    
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.cleanup()
            }
        }
    }
    
    private func cleanup() async {
        let now = Date()
        var expiredKeys: [Key] = []
        
        for (key, entry) in storage {
            if entry.isExpired {
                expiredKeys.append(key)
            }
        }
        
        for key in expiredKeys {
            storage.removeValue(forKey: key)
        }
    }
    
    private func evictLeastUsed() async {
        guard storage.count > maxSize else { return }
        
        // Sort by access frequency and last access time
        let sortedEntries = storage.sorted { first, second in
            if first.value.accessCount != second.value.accessCount {
                return first.value.accessCount < second.value.accessCount
            }
            return first.value.lastAccessed < second.value.lastAccessed
        }
        
        // Remove the least used entries
        let toRemove = storage.count - maxSize + 1
        for i in 0..<min(toRemove, sortedEntries.count) {
            storage.removeValue(forKey: sortedEntries[i].key)
        }
    }
}

// MARK: - Cache Manager

@MainActor
final class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    // Specialized caches for different data types
    private let priceCache = IntelligentCache<String, StreamPrice>(
        maxSize: 500,
        defaultTTL: 30 // 30 seconds for price data
    )
    
    private let historicalCache = IntelligentCache<String, [ChartData]>(
        maxSize: 100,
        defaultTTL: 300 // 5 minutes for historical data
    )
    
    private let currencyCache = IntelligentCache<String, Currency>(
        maxSize: 1000,
        defaultTTL: 3600 // 1 hour for currency info
    )
    
    private let exchangeCache = IntelligentCache<String, Exchange>(
        maxSize: 200,
        defaultTTL: 3600 // 1 hour for exchange info
    )
    
    @Published private(set) var statistics: CacheStatistics = CacheStatistics()
    
    private init() {
        startStatisticsUpdate()
    }
    
    // MARK: - Price Cache
    
    func getPrice(for key: String) async -> StreamPrice? {
        return await priceCache.get(key)
    }
    
    func setPrice(_ price: StreamPrice, for key: String) async {
        await priceCache.set(key, value: price)
    }
    
    // MARK: - Historical Data Cache
    
    func getHistoricalData(for key: String) async -> [ChartData]? {
        return await historicalCache.get(key)
    }
    
    func setHistoricalData(_ data: [ChartData], for key: String, ttl: TimeInterval? = nil) async {
        await historicalCache.set(key, value: data, ttl: ttl)
    }
    
    // MARK: - Currency Cache
    
    func getCurrency(for symbol: String) async -> Currency? {
        return await currencyCache.get(symbol)
    }
    
    func setCurrency(_ currency: Currency, for symbol: String) async {
        await currencyCache.set(symbol, value: currency)
    }
    
    // MARK: - Exchange Cache
    
    func getExchange(for id: String) async -> Exchange? {
        return await exchangeCache.get(id)
    }
    
    func setExchange(_ exchange: Exchange, for id: String) async {
        await exchangeCache.set(id, value: exchange)
    }
    
    // MARK: - Cache Control
    
    func clearAllCaches() async {
        await priceCache.clear()
        await historicalCache.clear()
        await currencyCache.clear()
        await exchangeCache.clear()
    }
    
    func clearPriceCache() async {
        await priceCache.clear()
    }
    
    private func startStatisticsUpdate() {
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateStatistics()
            }
        }
    }
    
    private func updateStatistics() async {
        let priceHitRate = await priceCache.hitRate
        let priceSize = await priceCache.currentSize
        let historicalHitRate = await historicalCache.hitRate
        let historicalSize = await historicalCache.currentSize
        let currencyHitRate = await currencyCache.hitRate
        let currencySize = await currencyCache.currentSize
        let exchangeHitRate = await exchangeCache.hitRate
        let exchangeSize = await exchangeCache.currentSize
        
        statistics = CacheStatistics(
            priceHitRate: priceHitRate,
            priceSize: priceSize,
            historicalHitRate: historicalHitRate,
            historicalSize: historicalSize,
            currencyHitRate: currencyHitRate,
            currencySize: currencySize,
            exchangeHitRate: exchangeHitRate,
            exchangeSize: exchangeSize
        )
    }
}

struct CacheStatistics {
    let priceHitRate: Double
    let priceSize: Int
    let historicalHitRate: Double
    let historicalSize: Int
    let currencyHitRate: Double
    let currencySize: Int
    let exchangeHitRate: Double
    let exchangeSize: Int
    
    init(
        priceHitRate: Double = 0,
        priceSize: Int = 0,
        historicalHitRate: Double = 0,
        historicalSize: Int = 0,
        currencyHitRate: Double = 0,
        currencySize: Int = 0,
        exchangeHitRate: Double = 0,
        exchangeSize: Int = 0
    ) {
        self.priceHitRate = priceHitRate
        self.priceSize = priceSize
        self.historicalHitRate = historicalHitRate
        self.historicalSize = historicalSize
        self.currencyHitRate = currencyHitRate
        self.currencySize = currencySize
        self.exchangeHitRate = exchangeHitRate
        self.exchangeSize = exchangeSize
    }
    
    var overallHitRate: Double {
        let rates = [priceHitRate, historicalHitRate, currencyHitRate, exchangeHitRate]
        let validRates = rates.filter { $0 > 0 }
        return validRates.isEmpty ? 0 : validRates.reduce(0, +) / Double(validRates.count)
    }
    
    var totalSize: Int {
        return priceSize + historicalSize + currencySize + exchangeSize
    }
}