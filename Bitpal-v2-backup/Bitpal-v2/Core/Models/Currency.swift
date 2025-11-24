//
//  Currency.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class Currency {
    @Attribute(.unique) var id: String
    var name: String
    var symbol: String
    var displaySymbol: String
    var createdAt: Date
    var lastModified: Date
    var isDeleted: Bool
    
    @Relationship(deleteRule: .nullify, inverse: \CurrencyPair.baseCurrency) 
    var basePairs: [CurrencyPair] = []
    
    @Relationship(deleteRule: .nullify, inverse: \CurrencyPair.quoteCurrency) 
    var quotePairs: [CurrencyPair] = []
    
    init(id: String, name: String, symbol: String, displaySymbol: String? = nil) {
        self.id = id.lowercased()
        self.name = name
        self.symbol = symbol.uppercased()
        self.displaySymbol = displaySymbol ?? symbol.uppercased()
        let now = Date()
        self.createdAt = now
        self.lastModified = now
        self.isDeleted = false
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

// MARK: - Factory Methods
extension Currency {
    static func bitcoin() -> Currency {
        Currency(id: "btc", name: "Bitcoin", symbol: "BTC", displaySymbol: "₿")
    }
    
    static func ethereum() -> Currency {
        Currency(id: "eth", name: "Ethereum", symbol: "ETH", displaySymbol: "Ξ")
    }
    
    static func usd() -> Currency {
        Currency(id: "usd", name: "US Dollar", symbol: "USD", displaySymbol: "$")
    }
    
    static func eur() -> Currency {
        Currency(id: "eur", name: "Euro", symbol: "EUR", displaySymbol: "€")
    }
    
    static func gbp() -> Currency {
        Currency(id: "gbp", name: "British Pound", symbol: "GBP", displaySymbol: "£")
    }
}

// MARK: - Computed Properties
extension Currency {
    var allPairs: [CurrencyPair] {
        basePairs + quotePairs
    }
    
    var isActive: Bool {
        !isDeleted
    }
    
    var displayName: String {
        "\(name) (\(symbol))"
    }
}

// MARK: - Codable
extension Currency: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, symbol, displaySymbol, createdAt, lastModified, isDeleted
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let symbol = try container.decode(String.self, forKey: .symbol)
        let displaySymbol = try container.decode(String.self, forKey: .displaySymbol)
        
        self.init(id: id, name: name, symbol: symbol, displaySymbol: displaySymbol)
        
        if let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) {
            self.createdAt = createdAt
        }
        if let lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) {
            self.lastModified = lastModified
        }
        if let isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) {
            self.isDeleted = isDeleted
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(displaySymbol, forKey: .displaySymbol)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
    }
}

// MARK: - Hashable & Equatable
extension Currency: Hashable {
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}