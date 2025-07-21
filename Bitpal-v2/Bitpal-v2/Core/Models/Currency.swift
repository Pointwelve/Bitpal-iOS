//
//  Currency.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class Currency: Codable {
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
        self.id = id
        self.name = name
        self.symbol = symbol
        self.displaySymbol = displaySymbol ?? symbol
        self.createdAt = Date()
        self.lastModified = Date()
        self.isDeleted = false
    }
    
    // Convenience initializer for common crypto currencies
    static func bitcoin() -> Currency {
        Currency(id: "btc", name: "Bitcoin", symbol: "BTC", displaySymbol: "₿")
    }
    
    static func ethereum() -> Currency {
        Currency(id: "eth", name: "Ethereum", symbol: "ETH", displaySymbol: "Ξ")
    }
    
    static func usd() -> Currency {
        Currency(id: "usd", name: "US Dollar", symbol: "USD", displaySymbol: "$")
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.displaySymbol = try container.decode(String.self, forKey: .displaySymbol)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        self.basePairs = []
        self.quotePairs = []
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
    
    private enum CodingKeys: String, CodingKey {
        case id, name, symbol, displaySymbol, createdAt, lastModified, isDeleted
    }
    
}

extension Currency: Hashable {
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}