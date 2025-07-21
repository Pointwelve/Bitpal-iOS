//
//  CurrencyPair.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class CurrencyPair: Codable {
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
    
    @Relationship(deleteRule: .cascade, inverse: \Alert.currencyPair) 
    var alerts: [Alert] = []
    
    @Relationship(deleteRule: .cascade, inverse: \HistoricalPrice.currencyPair) 
    var priceHistory: [HistoricalPrice] = []
    
    init(
        baseCurrency: Currency,
        quoteCurrency: Currency,
        exchange: Exchange,
        sortOrder: Int = 0
    ) {
        self.id = "\(baseCurrency.symbol)-\(quoteCurrency.symbol)-\(exchange.id)"
        self.baseCurrency = baseCurrency
        self.quoteCurrency = quoteCurrency
        self.exchange = exchange
        self.sortOrder = sortOrder
        self.currentPrice = 0
        self.priceChange24h = 0
        self.priceChangePercent24h = 0
        self.volume24h = 0
        self.high24h = 0
        self.low24h = 0
        self.open24h = 0
        self.marketCap = 0
        self.lastUpdated = Date()
        self.createdAt = Date()
        self.lastModified = Date()
        self.isDeleted = false
    }
    
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
        exchange?.displayName ?? "Unknown Exchange"
    }
    
    var isPositiveChange: Bool {
        priceChange24h >= 0
    }
    
    var reciprocalPrice: Double {
        currentPrice > 0 ? 1.0 / currentPrice : 0
    }
    
    var primaryKey: String {
        id
    }
    
    // Update price data from stream
    func updateFromStream(
        price: Double,
        volume24h: Double? = nil,
        high24h: Double? = nil,
        low24h: Double? = nil,
        open24h: Double? = nil,
        bid: Double? = nil,
        ask: Double? = nil
    ) {
        self.currentPrice = price
        
        if let volume = volume24h { self.volume24h = volume }
        if let high = high24h { self.high24h = high }
        if let low = low24h { self.low24h = low }
        if let open = open24h { 
            self.open24h = open
            self.priceChange24h = price - open
            self.priceChangePercent24h = open > 0 ? ((price - open) / open) * 100 : 0
        }
        if let bidPrice = bid { self.bid = bidPrice }
        if let askPrice = ask { self.ask = askPrice }
        
        self.lastUpdated = Date()
        self.lastModified = Date()
    }
    
    // Widget display data
    var widgetDisplayData: WidgetCurrencyData {
        WidgetCurrencyData(
            symbol: displayName,
            price: currentPrice,
            change: priceChangePercent24h,
            lastUpdated: lastUpdated
        )
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.sortOrder = try container.decode(Int.self, forKey: .sortOrder)
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
        self.baseCurrency = nil
        self.quoteCurrency = nil
        self.exchange = nil
        self.alerts = []
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
    
    private enum CodingKeys: String, CodingKey {
        case id, sortOrder, currentPrice, priceChange24h, priceChangePercent24h
        case volume24h, high24h, low24h, open24h, marketCap, bid, ask
        case lastUpdated, createdAt, lastModified, isDeleted
    }
    
}

// Shared widget data structure
struct WidgetCurrencyData: Codable, Sendable {
    let symbol: String
    let price: Double
    let change: Double
    let lastUpdated: Date
}