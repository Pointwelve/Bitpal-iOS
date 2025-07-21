//
//  Exchange.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class Exchange: Codable {
    @Attribute(.unique) var id: String
    var name: String
    var displayName: String
    var isActive: Bool
    var createdAt: Date
    var lastModified: Date
    var isDeleted: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \CurrencyPair.exchange) 
    var currencyPairs: [CurrencyPair] = []
    
    init(id: String, name: String, displayName: String? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.isActive = isActive
        self.createdAt = Date()
        self.lastModified = Date()
        self.isDeleted = false
    }
    
    // Common exchanges
    static func coinbase() -> Exchange {
        Exchange(id: "coinbase", name: "Coinbase", displayName: "Coinbase Pro")
    }
    
    static func binance() -> Exchange {
        Exchange(id: "binance", name: "Binance")
    }
    
    static func kraken() -> Exchange {
        Exchange(id: "kraken", name: "Kraken")
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        self.currencyPairs = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, displayName, isActive, createdAt, lastModified, isDeleted
    }
    
}

extension Exchange: Hashable {
    static func == (lhs: Exchange, rhs: Exchange) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}