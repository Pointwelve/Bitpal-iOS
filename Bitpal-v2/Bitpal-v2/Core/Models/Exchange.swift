//
//  Exchange.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class Exchange {
    @Attribute(.unique) var id: String
    var name: String
    var displayName: String
    var website: String?
    var logoURL: String?
    var country: String?
    var isActive: Bool
    var createdAt: Date
    var lastModified: Date
    var isDeleted: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \CurrencyPair.exchange) 
    var currencyPairs: [CurrencyPair] = []
    
    init(
        id: String, 
        name: String, 
        displayName: String? = nil,
        website: String? = nil,
        logoURL: String? = nil,
        country: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id.lowercased()
        self.name = name
        self.displayName = displayName ?? name
        self.website = website
        self.logoURL = logoURL
        self.country = country
        self.isActive = isActive
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
    
    func activate() {
        isActive = true
        lastModified = Date()
    }
    
    func deactivate() {
        isActive = false
        lastModified = Date()
    }
    
    func updateLastModified() {
        lastModified = Date()
    }
}

// MARK: - Factory Methods
extension Exchange {
    static func coinbase() -> Exchange {
        Exchange(
            id: "coinbase",
            name: "Coinbase",
            displayName: "Coinbase Pro",
            website: "https://pro.coinbase.com",
            country: "United States"
        )
    }
    
    static func binance() -> Exchange {
        Exchange(
            id: "binance",
            name: "Binance",
            website: "https://www.binance.com",
            country: "Malta"
        )
    }
    
    static func kraken() -> Exchange {
        Exchange(
            id: "kraken",
            name: "Kraken",
            website: "https://www.kraken.com",
            country: "United States"
        )
    }
    
    static func bitstamp() -> Exchange {
        Exchange(
            id: "bitstamp",
            name: "Bitstamp",
            website: "https://www.bitstamp.net",
            country: "Luxembourg"
        )
    }
    
    static func gemini() -> Exchange {
        Exchange(
            id: "gemini",
            name: "Gemini",
            website: "https://www.gemini.com",
            country: "United States"
        )
    }
    
    static func huobi() -> Exchange {
        Exchange(
            id: "huobi",
            name: "Huobi",
            website: "https://www.huobi.com",
            country: "Singapore"
        )
    }
    
    static func kucoin() -> Exchange {
        Exchange(
            id: "kucoin",
            name: "KuCoin",
            website: "https://www.kucoin.com",
            country: "Seychelles"
        )
    }
    
    static func okx() -> Exchange {
        Exchange(
            id: "okx",
            name: "OKX",
            displayName: "OKX (formerly OKEx)",
            website: "https://www.okx.com",
            country: "Malta"
        )
    }
}

// MARK: - Computed Properties
extension Exchange {
    var isAvailable: Bool {
        isActive && !isDeleted
    }
    
    var pairCount: Int {
        currencyPairs.count
    }
    
    var activePairCount: Int {
        currencyPairs.filter { !$0.isDeleted }.count
    }
    
    var hasWebsite: Bool {
        website != nil && !(website?.isEmpty ?? true)
    }
    
    var hasLogo: Bool {
        logoURL != nil && !(logoURL?.isEmpty ?? true)
    }
    
    var shortDisplayName: String {
        // Return shorter version if display name is very long
        if displayName.count > 15 {
            return name
        }
        return displayName
    }
    
    var countryFlag: String? {
        guard let country = country else { return nil }
        
        switch country.lowercased() {
        case "united states", "usa", "us":
            return "🇺🇸"
        case "malta":
            return "🇲🇹"
        case "luxembourg":
            return "🇱🇺"
        case "singapore":
            return "🇸🇬"
        case "seychelles":
            return "🇸🇨"
        case "united kingdom", "uk", "britain":
            return "🇬🇧"
        case "canada":
            return "🇨🇦"
        case "japan":
            return "🇯🇵"
        case "south korea", "korea":
            return "🇰🇷"
        case "china":
            return "🇨🇳"
        default:
            return nil
        }
    }
}

// MARK: - Business Logic
extension Exchange {
    func createPair(baseCurrency: Currency, quoteCurrency: Currency) -> CurrencyPair {
        let pair = CurrencyPair(
            baseCurrency: baseCurrency,
            quoteCurrency: quoteCurrency,
            exchange: self
        )
        return pair
    }
    
    func hasPair(base: String, quote: String) -> Bool {
        currencyPairs.contains { pair in
            pair.baseCurrency?.symbol.lowercased() == base.lowercased() &&
            pair.quoteCurrency?.symbol.lowercased() == quote.lowercased()
        }
    }
    
    func findPair(base: String, quote: String) -> CurrencyPair? {
        currencyPairs.first { pair in
            pair.baseCurrency?.symbol.lowercased() == base.lowercased() &&
            pair.quoteCurrency?.symbol.lowercased() == quote.lowercased()
        }
    }
    
    func activePairs() -> [CurrencyPair] {
        currencyPairs.filter { $0.isActive }
    }
}

// MARK: - Validation
extension Exchange {
    var isValidExchange: Bool {
        !id.isEmpty && !name.isEmpty && !displayName.isEmpty
    }
    
    var hasValidWebsite: Bool {
        guard let website = website else { return true } // Optional field
        return website.starts(with: "https://") || website.starts(with: "http://")
    }
    
    var isRecentlyUpdated: Bool {
        Date().timeIntervalSince(lastModified) < 86400 // 24 hours
    }
}

// MARK: - Codable
extension Exchange: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, name, displayName, website, logoURL, country
        case isActive, createdAt, lastModified, isDeleted
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        let website = try container.decodeIfPresent(String.self, forKey: .website)
        let logoURL = try container.decodeIfPresent(String.self, forKey: .logoURL)
        let country = try container.decodeIfPresent(String.self, forKey: .country)
        let isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        
        self.init(
            id: id,
            name: name,
            displayName: displayName,
            website: website,
            logoURL: logoURL,
            country: country,
            isActive: isActive
        )
        
        // Override with decoded timestamps if present
        if let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) {
            self.createdAt = createdAt
        }
        if let lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) {
            self.lastModified = lastModified
        }
        if let isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) {
            self.isDeleted = isDeleted
        }
        
        // Clear relationships - they'll be set by the persistence layer
        self.currencyPairs = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(logoURL, forKey: .logoURL)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
    }
}

// MARK: - Hashable & Equatable
extension Exchange: Hashable {
    static func == (lhs: Exchange, rhs: Exchange) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}