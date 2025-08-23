//
//  CurrencyPair.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class CurrencyPair {
    @Attribute(.unique) var id: String
    var sortOrder: Int
    var currentPrice: Double
    var priceChange24h: Double
    var priceChangePercent24h: Double
    var volume24h: Double
    var high24h: Double
    var low24h: Double
    var open24h: Double
    var marketCap: Double
    var bid: Double?
    var ask: Double?
    var lastUpdated: Date
    var createdAt: Date
    var lastModified: Date
    var isDeleted: Bool
    
    @Relationship(deleteRule: .nullify) var baseCurrency: Currency?
    @Relationship(deleteRule: .nullify) var quoteCurrency: Currency?
    @Relationship(deleteRule: .nullify) var exchange: Exchange?
    
    
    @Relationship(deleteRule: .cascade, inverse: \HistoricalPrice.currencyPair) 
    var priceHistory: [HistoricalPrice] = []
    
    init(
        baseCurrency: Currency,
        quoteCurrency: Currency,
        exchange: Exchange,
        sortOrder: Int = 0
    ) {
        self.id = Self.generateId(base: baseCurrency.symbol, quote: quoteCurrency.symbol, exchange: exchange.id)
        self.baseCurrency = baseCurrency
        self.quoteCurrency = quoteCurrency
        self.exchange = exchange
        self.sortOrder = sortOrder
        self.currentPrice = 0.0
        self.priceChange24h = 0.0
        self.priceChangePercent24h = 0.0
        self.volume24h = 0.0
        self.high24h = 0.0
        self.low24h = 0.0
        self.open24h = 0.0
        self.marketCap = 0.0
        let now = Date()
        self.lastUpdated = now
        self.createdAt = now
        self.lastModified = now
        self.isDeleted = false
    }
    
    init(
        baseCurrency: Currency,
        quoteCurrency: Currency,
        sortOrder: Int = 0
    ) {
        self.id = Self.generateId(base: baseCurrency.symbol, quote: quoteCurrency.symbol)
        self.baseCurrency = baseCurrency
        self.quoteCurrency = quoteCurrency
        self.exchange = nil
        self.sortOrder = sortOrder
        self.currentPrice = 0.0
        self.priceChange24h = 0.0
        self.priceChangePercent24h = 0.0
        self.volume24h = 0.0
        self.high24h = 0.0
        self.low24h = 0.0
        self.open24h = 0.0
        self.marketCap = 0.0
        let now = Date()
        self.lastUpdated = now
        self.createdAt = now
        self.lastModified = now
        self.isDeleted = false
    }
    
    private static func generateId(base: String, quote: String, exchange: String) -> String {
        "\(base.uppercased())-\(quote.uppercased())-\(exchange.lowercased())"
    }
    
    private static func generateId(base: String, quote: String) -> String {
        "\(base.uppercased())-\(quote.uppercased())"
    }
    
    func markAsDeleted() {
        isDeleted = true
        lastModified = Date()
    }
    
    func restore() {
        isDeleted = false
        lastModified = Date()
    }
    
    func updateLastModified() {
        lastModified = Date()
    }
}

// MARK: - Price Update Methods
extension CurrencyPair {
    func updateFromStream(
        price: Double,
        volume24h: Double? = nil,
        high24h: Double? = nil,
        low24h: Double? = nil,
        open24h: Double? = nil,
        bid: Double? = nil,
        ask: Double? = nil,
        directChange24h: Double? = nil,
        directChangePercent24h: Double? = nil
    ) {
        guard price >= 0 else { return }
        
        self.currentPrice = price
        
        if let volume = volume24h, volume >= 0 { 
            self.volume24h = volume 
        }
        if let high = high24h, high >= 0 { 
            self.high24h = high 
        }
        if let low = low24h, low >= 0 { 
            self.low24h = low 
        }
        
        if let open = open24h, open > 0 { 
            self.open24h = open
            calculateChangeFromOpen(currentPrice: price, openPrice: open)
        } else if let change = directChange24h, let changePercent = directChangePercent24h {
            updateWithDirectChange(price: price, change: change, changePercent: changePercent)
        }
        // If neither open24h nor direct values provided, preserve existing percentage data
        // This prevents WebSocket updates from wiping out API-calculated percentages
        
        if let bidPrice = bid, bidPrice >= 0 { 
            self.bid = bidPrice 
        }
        if let askPrice = ask, askPrice >= 0 { 
            self.ask = askPrice 
        }
        
        self.lastUpdated = Date()
        self.lastModified = Date()
    }
    
    private func calculateChangeFromOpen(currentPrice: Double, openPrice: Double) {
        self.priceChange24h = currentPrice - openPrice
        self.priceChangePercent24h = openPrice > 0 ? ((currentPrice - openPrice) / openPrice) * 100 : 0
    }
    
    private func updateWithDirectChange(price: Double, change: Double, changePercent: Double) {
        self.priceChange24h = change
        self.priceChangePercent24h = changePercent
        if change != 0 {
            self.open24h = price - change
        }
    }
}

// MARK: - Computed Properties
extension CurrencyPair {
    var displayName: String {
        guard let base = baseCurrency?.symbol, let quote = quoteCurrency?.symbol else {
            return "Unknown Pair"
        }
        return "\(base)/\(quote)"
    }
    
    var displaySymbols: String {
        guard let base = baseCurrency?.displaySymbol, let quote = quoteCurrency?.displaySymbol else {
            return displayName
        }
        return "\(base)/\(quote)"
    }
    
    var exchangeName: String {
        exchange?.displayName ?? "Aggregated"
    }
    
    var isPositiveChange: Bool {
        priceChange24h >= 0
    }
    
    var isActive: Bool {
        !isDeleted
    }
    
    var reciprocalPrice: Double {
        currentPrice > 0 ? 1.0 / currentPrice : 0
    }
    
    var spread: Double? {
        guard let bidPrice = bid, let askPrice = ask, askPrice > bidPrice else { return nil }
        return askPrice - bidPrice
    }
    
    var spreadPercent: Double? {
        guard let spreadValue = spread, let askPrice = ask, askPrice > 0 else { return nil }
        return (spreadValue / askPrice) * 100
    }
    
    var priceRange24h: Double {
        high24h - low24h
    }
    
    var priceRangePercent24h: Double {
        guard low24h > 0 else { return 0 }
        return (priceRange24h / low24h) * 100
    }
    
    var isWithinDayRange: Bool {
        currentPrice >= low24h && currentPrice <= high24h
    }
    
    var primaryKey: String {
        id
    }
    
    var widgetDisplayData: WidgetCurrencyData {
        WidgetCurrencyData(
            symbol: displayName,
            price: currentPrice,
            change: priceChangePercent24h,
            lastUpdated: lastUpdated
        )
    }
}

// MARK: - Business Logic
extension CurrencyPair {
    func calculateValue(quantity: Double) -> Double {
        quantity * currentPrice
    }
    
    func formatPrice(using formatter: NumberFormatter? = nil) -> String {
        let defaultFormatter = NumberFormatter()
        defaultFormatter.numberStyle = .currency
        defaultFormatter.currencyCode = quoteCurrency?.symbol ?? "USD"
        
        let activeFormatter = formatter ?? defaultFormatter
        return activeFormatter.string(from: NSNumber(value: currentPrice)) ?? "\(currentPrice)"
    }
    
    func formatChange(using formatter: NumberFormatter? = nil) -> String {
        let defaultFormatter = NumberFormatter()
        defaultFormatter.numberStyle = .percent
        defaultFormatter.minimumFractionDigits = 2
        defaultFormatter.maximumFractionDigits = 2
        
        let activeFormatter = formatter ?? defaultFormatter
        return activeFormatter.string(from: NSNumber(value: priceChangePercent24h / 100)) ?? "\(priceChangePercent24h)%"
    }
}

// MARK: - Validation
extension CurrencyPair {
    var isValidPair: Bool {
        baseCurrency != nil && quoteCurrency != nil
    }
    
    var hasRecentData: Bool {
        Date().timeIntervalSince(lastUpdated) < 3600 // 1 hour
    }
    
    var hasCompleteMarketData: Bool {
        currentPrice > 0 && volume24h >= 0 && high24h >= low24h
    }
}

// MARK: - Codable
extension CurrencyPair: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, sortOrder, currentPrice, priceChange24h, priceChangePercent24h
        case volume24h, high24h, low24h, open24h, marketCap, bid, ask
        case lastUpdated, createdAt, lastModified, isDeleted
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        
        // Create with minimal data, will be set properly below
        self.init(
            baseCurrency: Currency.usd(), // Temporary
            quoteCurrency: Currency.usd(), // Temporary  
            exchange: Exchange.coinbase(), // Temporary
            sortOrder: sortOrder
        )
        
        // Override with decoded values
        self.id = id
        self.currentPrice = try container.decode(Double.self, forKey: .currentPrice)
        self.priceChange24h = try container.decode(Double.self, forKey: .priceChange24h)
        self.priceChangePercent24h = try container.decode(Double.self, forKey: .priceChangePercent24h)
        self.volume24h = try container.decode(Double.self, forKey: .volume24h)
        self.high24h = try container.decode(Double.self, forKey: .high24h)
        self.low24h = try container.decode(Double.self, forKey: .low24h)
        self.open24h = try container.decode(Double.self, forKey: .open24h)
        self.marketCap = try container.decode(Double.self, forKey: .marketCap)
        self.bid = try container.decodeIfPresent(Double.self, forKey: .bid)
        self.ask = try container.decodeIfPresent(Double.self, forKey: .ask)
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        
        // Clear relationships - they'll be set by the persistence layer
        self.baseCurrency = nil
        self.quoteCurrency = nil
        self.exchange = nil
        self.priceHistory = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(currentPrice, forKey: .currentPrice)
        try container.encode(priceChange24h, forKey: .priceChange24h)
        try container.encode(priceChangePercent24h, forKey: .priceChangePercent24h)
        try container.encode(volume24h, forKey: .volume24h)
        try container.encode(high24h, forKey: .high24h)
        try container.encode(low24h, forKey: .low24h)
        try container.encode(open24h, forKey: .open24h)
        try container.encode(marketCap, forKey: .marketCap)
        try container.encodeIfPresent(bid, forKey: .bid)
        try container.encodeIfPresent(ask, forKey: .ask)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
    }
}

// MARK: - Hashable & Equatable
extension CurrencyPair: Hashable {
    static func == (lhs: CurrencyPair, rhs: CurrencyPair) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Types
struct WidgetCurrencyData: Codable, Sendable {
    let symbol: String
    let price: Double
    let change: Double
    let lastUpdated: Date
}