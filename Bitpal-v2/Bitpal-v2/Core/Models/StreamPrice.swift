//
//  StreamPrice.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

struct CoinDeskCurrentHourData: Codable, Sendable {
    let volume: Double?
    let quoteVolume: Double?
    let open: Double?
    let high: Double?
    let low: Double?
    let totalIndexUpdates: Double?
    let change: Double?
    let changePercentage: Double?
    
    private enum CodingKeys: String, CodingKey {
        case volume = "CURRENT_HOUR_VOLUME"
        case quoteVolume = "CURRENT_HOUR_QUOTE_VOLUME"
        case open = "CURRENT_HOUR_OPEN"
        case high = "CURRENT_HOUR_HIGH"
        case low = "CURRENT_HOUR_LOW"
        case totalIndexUpdates = "CURRENT_HOUR_TOTAL_INDEX_UPDATES"
        case change = "CURRENT_HOUR_CHANGE"
        case changePercentage = "CURRENT_HOUR_CHANGE_PERCENTAGE"
    }
    
    // Direct initializer for when we have individual values
    init(volume: Double?, open: Double?, high: Double?, low: Double?) {
        self.volume = volume
        self.quoteVolume = nil
        self.open = open
        self.high = high
        self.low = low
        self.totalIndexUpdates = nil
        self.change = nil
        self.changePercentage = nil
    }
}

struct CoinDeskCurrentDayData: Codable, Sendable {
    let volume: Double?
    let quoteVolume: Double?
    let open: Double?
    let high: Double?
    let low: Double?
    let totalIndexUpdates: Double?
    let change: Double?
    let changePercentage: Double?
    
    private enum CodingKeys: String, CodingKey {
        case volume = "CURRENT_DAY_VOLUME"
        case quoteVolume = "CURRENT_DAY_QUOTE_VOLUME"
        case open = "CURRENT_DAY_OPEN"
        case high = "CURRENT_DAY_HIGH"
        case low = "CURRENT_DAY_LOW"
        case totalIndexUpdates = "CURRENT_DAY_TOTAL_INDEX_UPDATES"
        case change = "CURRENT_DAY_CHANGE"
        case changePercentage = "CURRENT_DAY_CHANGE_PERCENTAGE"
    }
}

struct CoinDeskMoving24HourData: Codable, Sendable {
    let volume: Double?
    let quoteVolume: Double?
    let open: Double?
    let high: Double?
    let low: Double?
    let totalIndexUpdates: Double?
    let change: Double?
    let changePercentage: Double?
    
    private enum CodingKeys: String, CodingKey {
        case volume = "MOVING_24_HOUR_VOLUME"
        case quoteVolume = "MOVING_24_HOUR_QUOTE_VOLUME"
        case open = "MOVING_24_HOUR_OPEN"
        case high = "MOVING_24_HOUR_HIGH"
        case low = "MOVING_24_HOUR_LOW"
        case totalIndexUpdates = "MOVING_24_HOUR_TOTAL_INDEX_UPDATES"
        case change = "MOVING_24_HOUR_CHANGE"
        case changePercentage = "MOVING_24_HOUR_CHANGE_PERCENTAGE"
    }
}

struct StreamPrice: Codable, Sendable {
    // CoinDesk Core Fields (following schema exactly)
    let type: String?
    let messageType: Int?
    let market: String?
    let instrument: String?
    let ccseq: Double?
    let value: Double?
    let valueFlag: String?
    let valueLastUpdateTs: Double?
    let valueLastUpdateTsNs: Double?
    
    // CoinDesk Time-Based Data
    let currentHour: CoinDeskCurrentHourData?
    let currentDay: CoinDeskCurrentDayData?
    let moving24Hour: CoinDeskMoving24HourData?
    
    // Legacy fields for backward compatibility
    let exchange: String?
    let baseCurrency: String
    let quoteCurrency: String
    let price: Double?
    let bid: Double?
    let ask: Double?
    let lastUpdateTimeStamp: Int?
    let avg: Double?
    let lastVolume: Double?
    let lastVolumeTo: Double?
    let lastTradeId: String?
    let volumeHour: Double?
    let volumeHourTo: Double?
    let volume24h: Double?
    let volume24hTo: Double?
    let openHour: Double?
    let highHour: Double?
    let lowHour: Double?
    let open24Hour: Double?
    let high24Hour: Double?
    let low24Hour: Double?
    let lastMarket: String?
    let mask: String?
    
    private enum CodingKeys: String, CodingKey {
        // CoinDesk Core Fields
        case type = "TYPE"
        case messageType = "message_type"
        case market = "MARKET"
        case instrument = "INSTRUMENT"
        case ccseq = "CCSEQ"
        case value = "VALUE"
        case valueFlag = "VALUE_FLAG"
        case valueLastUpdateTs = "VALUE_LAST_UPDATE_TS"
        case valueLastUpdateTsNs = "VALUE_LAST_UPDATE_TS_NS"
        
        // Time-based data (will be parsed from the same response)
        case currentHour = "_current_hour_placeholder"
        case currentDay = "_current_day_placeholder"
        case moving24Hour = "_moving_24_hour_placeholder"
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode CoinDesk format first
        type = try container.decodeIfPresent(String.self, forKey: .type)
        messageType = try container.decodeIfPresent(Int.self, forKey: .messageType)
        market = try container.decodeIfPresent(String.self, forKey: .market)
        instrument = try container.decodeIfPresent(String.self, forKey: .instrument)
        ccseq = try container.decodeIfPresent(Double.self, forKey: .ccseq)
        value = try container.decodeIfPresent(Double.self, forKey: .value)
        valueFlag = try container.decodeIfPresent(String.self, forKey: .valueFlag)
        valueLastUpdateTs = try container.decodeIfPresent(Double.self, forKey: .valueLastUpdateTs)
        valueLastUpdateTsNs = try container.decodeIfPresent(Double.self, forKey: .valueLastUpdateTsNs)
        
        // Parse time-based data from the same container (CoinDesk format)
        // The CoinDeskCurrentHourData struct will handle the CURRENT_HOUR_* fields directly
        currentHour = try? CoinDeskCurrentHourData(from: decoder)
        currentDay = try? CoinDeskCurrentDayData(from: decoder)
        moving24Hour = try? CoinDeskMoving24HourData(from: decoder)
        
        // Extract currency symbols from instrument (CoinDesk format)
        if let instrumentName = instrument {
            let parts = instrumentName.split(separator: "-")
            if parts.count >= 2 {
                baseCurrency = String(parts[0])
                quoteCurrency = String(parts[1])
            } else {
                baseCurrency = ""
                quoteCurrency = ""
            }
        } else {
            baseCurrency = ""
            quoteCurrency = ""
        }
        
        // Map CoinDesk value to price
        price = value
        
        // CoinDesk-only fields (no legacy CryptoCompare support)
        exchange = nil
        bid = nil
        ask = nil
        lastUpdateTimeStamp = Int(valueLastUpdateTs ?? 0) != 0 ? Int(valueLastUpdateTs!) : nil
        avg = nil
        lastVolume = nil
        lastVolumeTo = nil
        lastTradeId = nil
        volumeHour = currentHour?.volume
        volumeHourTo = nil
        volume24h = moving24Hour?.volume
        volume24hTo = nil
        openHour = currentHour?.open
        highHour = currentHour?.high
        lowHour = currentHour?.low
        open24Hour = moving24Hour?.open
        high24Hour = moving24Hour?.high
        low24Hour = moving24Hour?.low
        lastMarket = nil
        mask = nil
    }
    
    var uniqueKey: String {
        if let instrumentName = instrument {
            return "\(market ?? "cadli")-\(instrumentName)"
        }
        return "\(baseCurrency)-\(quoteCurrency)"
    }
    
    var exchangeKey: String {
        market ?? "cadli"
    }
    
    var priceChange24h: Double {
        guard let current = price, let open = open24Hour, open > 0 else { 
            return 0 
        }
        return current - open
    }
    
    var priceChangePercent24h: Double {
        guard let current = price, let open = open24Hour, open > 0 else { 
            return 0 
        }
        return ((current - open) / open) * 100
    }
    
    var isPositiveChange: Bool {
        priceChange24h >= 0
    }
    
    // MARK: - Encodable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(messageType, forKey: .messageType)
        try container.encodeIfPresent(market, forKey: .market)
        try container.encodeIfPresent(instrument, forKey: .instrument)
        try container.encodeIfPresent(ccseq, forKey: .ccseq)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encodeIfPresent(valueFlag, forKey: .valueFlag)
        try container.encodeIfPresent(valueLastUpdateTs, forKey: .valueLastUpdateTs)
        try container.encodeIfPresent(valueLastUpdateTsNs, forKey: .valueLastUpdateTsNs)
        
        // Encode the complex time-based data objects
        try container.encodeIfPresent(currentHour, forKey: .currentHour)
        try container.encodeIfPresent(currentDay, forKey: .currentDay)
        try container.encodeIfPresent(moving24Hour, forKey: .moving24Hour)
        
        // For other properties that aren't in CodingKeys, we'll encode them manually
        // using a separate container if needed for persistence
    }
}

// MARK: - Price Change Calculation Helpers
extension StreamPrice {
    var hourlyChange: Double {
        guard let current = price, let open = openHour, open > 0 else { return 0 }
        return current - open
    }
    
    var hourlyChangePercent: Double {
        guard let current = price, let open = openHour, open > 0 else { return 0 }
        return ((current - open) / open) * 100
    }
    
    var spread: Double {
        guard let bidPrice = bid, let askPrice = ask else { return 0 }
        return askPrice - bidPrice
    }
    
    var spreadPercent: Double {
        guard let _ = bid, let askPrice = ask, askPrice > 0 else { return 0 }
        return (spread / askPrice) * 100
    }
}

// MARK: - Display Helpers
extension StreamPrice {
    var displayName: String {
        "\(baseCurrency)/\(quoteCurrency)"
    }
    
    var formattedPrice: String {
        guard let price = price else { return "N/A" }
        return formatPrice(price)
    }
    
    var formattedVolume24h: String {
        guard let volume = volume24h else { return "N/A" }
        return formatVolume(volume)
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price > 1000 {
            return String(format: "$%.0f", price)
        } else if price > 1 {
            return String(format: "$%.2f", price)
        } else if price > 0.01 {
            return String(format: "$%.4f", price)
        } else {
            return String(format: "$%.8f", price)
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume > 1_000_000_000 {
            return String(format: "%.2fB", volume / 1_000_000_000)
        } else if volume > 1_000_000 {
            return String(format: "%.2fM", volume / 1_000_000)
        } else if volume > 1_000 {
            return String(format: "%.2fK", volume / 1_000)
        } else {
            return String(format: "%.2f", volume)
        }
    }
}

// MARK: - Validation
extension StreamPrice {
    var isValidPriceData: Bool {
        guard let price = price, price > 0 else { return false }
        return !baseCurrency.isEmpty && !quoteCurrency.isEmpty && (exchange?.isEmpty == false || exchange == nil)
    }
    
    var hasCompleteMarketData: Bool {
        return isValidPriceData && 
               volume24h != nil && 
               high24Hour != nil && 
               low24Hour != nil && 
               open24Hour != nil
    }
}