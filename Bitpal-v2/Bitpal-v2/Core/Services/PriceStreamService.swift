//
//  PriceStreamService.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import Observation
import SwiftData
import WidgetKit

@MainActor
@Observable
final class PriceStreamService {
    static let shared = PriceStreamService()
    
    private(set) var prices: [String: StreamPrice] = [:]
    private(set) var isStreaming = false
    private(set) var connectionState: WebSocketManager.ConnectionState = .disconnected
    
    private let webSocketManager = WebSocketManager()
    private let apiClient = APIClient.shared
    private var modelContext: ModelContext?
    
    // Batch update optimization
    private var pendingUpdates: [String: StreamPrice] = [:]
    private var updateTimer: Timer?
    private let updateBatchInterval: TimeInterval = 2.0
    
    private init() {
        setupWebSocketBindings()
        startBatchUpdateTimer()
    }
    
    deinit {
        Task { @MainActor in
            updateTimer?.invalidate()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }
    
    func setAPIKey(_ key: String) async {
        webSocketManager.setAPIKey(key)
        await apiClient.setAPIKey(key)
    }
    
    private func setupWebSocketBindings() {
        webSocketManager.onPriceUpdate = { [weak self] streamPrice in
            Task { @MainActor in
                self?.updatePrice(streamPrice)
            }
        }
    }
    
    func startStreaming(for pairs: [CurrencyPair]) async {
        guard !pairs.isEmpty else { return }
        
        await webSocketManager.connect()
        
        for pair in pairs {
            guard let base = pair.baseCurrency?.symbol,
                  let quote = pair.quoteCurrency?.symbol else { continue }
            
            let instrument = "\(base)-\(quote)"
            await webSocketManager.subscribe(to: instrument)
        }
        
        isStreaming = true
    }
    
    func stopStreaming() async {
        webSocketManager.disconnect()
        isStreaming = false
        prices.removeAll()
        
        // Process any remaining pending updates before stopping
        await processBatchUpdates()
    }
    
    func subscribe(to pair: CurrencyPair) async {
        guard let base = pair.baseCurrency?.symbol,
              let quote = pair.quoteCurrency?.symbol else { return }
        
        let instrument = "\(base)-\(quote)"
        await webSocketManager.subscribe(to: instrument)
    }
    
    func unsubscribe(from pair: CurrencyPair) async {
        guard let base = pair.baseCurrency?.symbol,
              let quote = pair.quoteCurrency?.symbol else { return }
        
        let instrument = "\(base)-\(quote)"
        await webSocketManager.unsubscribe(from: instrument)
        
        // Remove from local cache using instrument key format
        prices.removeValue(forKey: instrument)
    }
    
    func updatePrice(_ streamPrice: StreamPrice) {
        let key = streamPrice.uniqueKey
        prices[key] = streamPrice
        
        // Add to pending batch updates instead of immediate processing
        pendingUpdates[key] = streamPrice
        
        // Check alerts immediately (critical for user notifications)
        Task {
            await AlertService.shared.checkAlerts(with: streamPrice)
        }
    }
    
    private func startBatchUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateBatchInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.processBatchUpdates()
            }
        }
    }
    
    private func processBatchUpdates() async {
        guard !pendingUpdates.isEmpty else { return }
        
        let currentBatch = pendingUpdates
        pendingUpdates.removeAll()
        
        // Batch update SwiftData
        await updateSwiftDataPrices(Array(currentBatch.values))
        
        // Update widgets (only once per batch)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func updateSwiftDataPrices(_ streamPrices: [StreamPrice]) async {
        guard let modelContext = modelContext, !streamPrices.isEmpty else { return }
        
        do {
            let allPairs = try modelContext.fetch(FetchDescriptor<CurrencyPair>())
            var hasChanges = false
            
            for streamPrice in streamPrices {
                let matchingPairs = allPairs.filter { pair in
                    pair.baseCurrency?.symbol == streamPrice.baseCurrency &&
                    pair.quoteCurrency?.symbol == streamPrice.quoteCurrency
                }
                
                if let pair = matchingPairs.first, let price = streamPrice.price {
                    // Map CoinDesk data to legacy format - prefer 24h moving data for consistency
                    let volume24h = streamPrice.moving24Hour?.volume ?? streamPrice.currentDay?.volume ?? streamPrice.volume24h
                    let high24h = streamPrice.moving24Hour?.high ?? streamPrice.currentDay?.high ?? streamPrice.high24Hour
                    let low24h = streamPrice.moving24Hour?.low ?? streamPrice.currentDay?.low ?? streamPrice.low24Hour
                    let open24h = streamPrice.moving24Hour?.open ?? streamPrice.currentDay?.open ?? streamPrice.open24Hour
                    
                    pair.updateFromStream(
                        price: price,
                        volume24h: volume24h,
                        high24h: high24h,
                        low24h: low24h,
                        open24h: open24h,
                        bid: streamPrice.bid,
                        ask: streamPrice.ask
                    )
                    hasChanges = true
                }
            }
            
            // Only save if there were actual changes
            if hasChanges {
                try modelContext.save()
            }
        } catch {
            print("Failed to batch update prices in SwiftData: \(error)")
        }
    }
    
    func fetchLatestPrices(for pairs: [CurrencyPair]) async throws {
        guard !pairs.isEmpty else { 
            print("❌ No currency pairs to fetch prices for")
            return 
        }
        
        let symbols = pairs.compactMap { $0.baseCurrency?.symbol }
        let currencies = pairs.compactMap { $0.quoteCurrency?.symbol }
        
        let uniqueSymbols = Array(Set(symbols))
        let uniqueCurrencies = Array(Set(currencies))
        
        print("🔄 Fetching prices for symbols: \(uniqueSymbols), currencies: \(uniqueCurrencies)")
        
        let response: PriceMultiResponse = try await apiClient.request(
            CryptoAPIEndpoint.priceMulti(symbols: uniqueSymbols, currencies: uniqueCurrencies)
        )
        
        print("✅ Received price response with \(response.data.count) instruments")
        print("📊 Response keys: \(Array(response.data.keys))")
        
        // Update prices in SwiftData
        await updatePricesFromAPI(response, pairs: pairs)
    }
    
    private func updatePricesFromAPI(_ response: PriceMultiResponse, pairs: [CurrencyPair]) async {
        guard let modelContext = modelContext else { 
            print("❌ No model context available for price updates")
            return 
        }
        
        print("🔄 Updating prices for \(pairs.count) currency pairs")
        
        for pair in pairs {
            guard let baseSymbol = pair.baseCurrency?.symbol,
                  let quoteSymbol = pair.quoteCurrency?.symbol else { 
                print("⚠️ Skipping pair with missing symbols: \(pair.displayName)")
                continue 
            }
            
            // Find matching price data from CoinDesk response
            let instrumentKey = "\(baseSymbol)-\(quoteSymbol)".uppercased()
            print("🔍 Looking for instrument key: '\(instrumentKey)'")
            
            guard let tickData = response.data[instrumentKey] else { 
                print("❌ No price data found for '\(instrumentKey)'")
                print("Available keys: \(Array(response.data.keys))")
                continue 
            }
            
            // Extract all available data from PriceMultiResponse
            let currentPrice = pair.currentPrice
            let apiPrice = tickData.value
            let apiOpen24h = tickData.currentDayOpen
            let apiHigh24h = tickData.currentDayHigh
            let apiLow24h = tickData.currentDayLow
            let apiChange24h = tickData.currentDayChange
            let apiChangePercent24h = tickData.currentDayChangePercentage
            
            print("💰 PriceMultiResponse data for \(instrumentKey):")
            print("   Current: \(apiPrice)")
            print("   Open24h: \(apiOpen24h ?? 0)")
            print("   High24h: \(apiHigh24h ?? 0)")
            print("   Low24h: \(apiLow24h ?? 0)")
            print("   Change24h: \(apiChange24h ?? 0)")
            print("   ChangePercent24h: \(apiChangePercent24h ?? 0)%")
            
            // Prioritize PriceMultiResponse data - use direct API values first
            if let change = apiChange24h, let changePercent = apiChangePercent24h {
                // Use pre-calculated values from CoinDesk API
                pair.updateFromStream(
                    price: apiPrice,
                    volume24h: nil,
                    high24h: apiHigh24h,
                    low24h: apiLow24h,
                    open24h: apiOpen24h,
                    bid: nil,
                    ask: nil,
                    directChange24h: change,
                    directChangePercent24h: changePercent
                )
                print("✅ Used direct PriceMultiResponse values: \(change) (\(changePercent)%)")
            } else if let open = apiOpen24h {
                // Fallback: calculate from open24h if direct values not available
                pair.updateFromStream(
                    price: apiPrice,
                    volume24h: nil,
                    high24h: apiHigh24h,
                    low24h: apiLow24h,
                    open24h: open,
                    bid: nil,
                    ask: nil
                )
                print("✅ Calculated from PriceMultiResponse open24h: \(open)")
            } else {
                // Last resort: just update price
                pair.updateFromStream(price: apiPrice)
                print("⚠️ Only price available from PriceMultiResponse")
            }
            
            print("✅ Updated \(instrumentKey) from \(currentPrice) to \(apiPrice)")
            print("💾 Final 24h change: \(pair.priceChange24h) (\(pair.priceChangePercent24h)%)")
            
            // Create price history entry if price changed significantly
            if currentPrice > 0 && abs(apiPrice - currentPrice) / currentPrice > 0.001 { // 0.1% change threshold
                let currentTime = Date()
                let historicalPrice = HistoricalPrice(
                    currencyPair: pair,
                    timestamp: Int(currentTime.timeIntervalSince1970),
                    open: currentPrice,
                    high: max(currentPrice, apiPrice),
                    low: min(currentPrice, apiPrice),
                    close: apiPrice,
                    period: .oneMinute
                )
                modelContext.insert(historicalPrice)
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save updated prices: \(error)")
        }
    }
    
    func fetchHistoricalData(
        for pair: CurrencyPair, 
        period: ChartPeriod, 
        limit: Int = 100
    ) async throws -> [ChartData] {
        guard let baseSymbol = pair.baseCurrency?.symbol,
              let quoteSymbol = pair.quoteCurrency?.symbol else {
            throw NetworkError.invalidURL
        }
        
        let response: HistoricalDataResponse = try await apiClient.request(
            CryptoAPIEndpoint.priceHistorical(
                symbol: baseSymbol,
                currency: quoteSymbol,
                exchange: pair.exchange?.id,
                period: period,
                limit: limit
            )
        )
        
        return response.data.compactMap { data in
            ChartData(
                id: "\(pair.id)-\(data.time)",
                date: Date(timeIntervalSince1970: TimeInterval(data.time)),
                open: data.open,
                high: data.high,
                low: data.low,
                close: data.close,
                volume: data.volumeFrom
            )
        }
    }
    
    func getCurrentPrice(for symbol: String) -> Double {
        for (_, streamPrice) in prices {
            if streamPrice.baseCurrency == symbol {
                return streamPrice.price ?? 0
            }
        }
        return 0
    }
    
    // Background refresh for widgets and Live Activities
    func backgroundRefresh() async {
        // Fetch latest prices for watchlist items
        // This would be called from background tasks
    }
}

// Response models for API
// HistoricalDataResponse is defined in HistoricalDataService.swift

// HistoricalDataPoint is defined in HistoricalDataService.swift