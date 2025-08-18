//
//  HistoricalPrice.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class HistoricalPrice {
    @Attribute(.unique) var id: String
    var timestamp: Int
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volumeFrom: Double
    var volumeTo: Double
    var period: ChartPeriod
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify) var currencyPair: CurrencyPair?
    
    init(
        currencyPair: CurrencyPair,
        timestamp: Int,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        volumeFrom: Double = 0,
        volumeTo: Double = 0,
        period: ChartPeriod
    ) {
        self.id = "\(currencyPair.id)-\(timestamp)-\(period.rawValue)"
        self.currencyPair = currencyPair
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volumeFrom = volumeFrom
        self.volumeTo = volumeTo
        self.period = period
        self.createdAt = Date()
    }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    var priceChange: Double {
        close - open
    }
    
    var priceChangePercent: Double {
        open > 0 ? ((close - open) / open) * 100 : 0
    }
    
    var isPositive: Bool {
        close >= open
    }
    
    // For chart display
    var chartData: ChartData {
        ChartData(
            id: id,
            date: date,
            open: open,
            high: high,
            low: low,
            close: close,
            volume: volumeFrom
        )
    }
}

enum ChartPeriod: String, CaseIterable, Codable, Sendable {
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case thirtyMinutes = "30m"
    case oneHour = "1h"
    case fourHours = "4h"
    case oneDay = "1d"
    case oneWeek = "1w"
    case oneMonth = "1M"
    
    var displayName: String {
        switch self {
        case .oneMinute: return "1m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .oneHour: return "1h"
        case .fourHours: return "4h"
        case .oneDay: return "1d"
        case .oneWeek: return "1w"
        case .oneMonth: return "1M"
        }
    }
    
    var seconds: Int {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .thirtyMinutes: return 1800
        case .oneHour: return 3600
        case .fourHours: return 14400
        case .oneDay: return 86400
        case .oneWeek: return 604800
        case .oneMonth: return 2629746
        }
    }
    
    var dataPointCount: Int {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 60
        case .fifteenMinutes: return 60
        case .thirtyMinutes: return 48
        case .oneHour: return 60
        case .fourHours: return 48
        case .oneDay: return 24
        case .oneWeek: return 168
        case .oneMonth: return 30
        }
    }
    
    var intervalMinutes: Int {
        switch self {
        case .oneMinute: return 1
        case .fiveMinutes: return 5
        case .fifteenMinutes: return 15
        case .thirtyMinutes: return 30
        case .oneHour: return 60
        case .fourHours: return 240
        case .oneDay: return 1440
        case .oneWeek: return 10080
        case .oneMonth: return 43200
        }
    }
    
    var xAxisStride: Calendar.Component {
        switch self {
        case .oneMinute: return .minute
        case .fiveMinutes: return .minute
        case .fifteenMinutes: return .minute
        case .thirtyMinutes: return .minute
        case .oneHour: return .hour
        case .fourHours: return .hour
        case .oneDay: return .hour
        case .oneWeek: return .day
        case .oneMonth: return .day
        }
    }
    
    var xAxisFormat: Date.FormatStyle {
        switch self {
        case .oneMinute, .fiveMinutes, .fifteenMinutes, .thirtyMinutes: 
            return .dateTime.hour().minute()
        case .oneHour, .fourHours: 
            return .dateTime.hour()
        case .oneDay: 
            return .dateTime.hour()
        case .oneWeek, .oneMonth: 
            return .dateTime.month().day()
        }
    }
    
    var limit: Int {
        switch self {
        case .oneMinute, .fiveMinutes: return 100
        case .fifteenMinutes, .thirtyMinutes: return 200
        case .oneHour: return 500
        case .fourHours: return 730
        case .oneDay: return 365
        case .oneWeek: return 52
        case .oneMonth: return 24
        }
    }
    
    var aggregateValue: Int {
        switch self {
        case .oneMinute: return 1
        case .fiveMinutes: return 5
        case .fifteenMinutes: return 15
        case .thirtyMinutes: return 30
        case .oneHour: return 1
        case .fourHours: return 4
        case .oneDay: return 1
        case .oneWeek: return 1
        case .oneMonth: return 1
        }
    }
}

// Chart data structure for SwiftUI Charts
struct ChartData: Identifiable, Sendable, Equatable {
    let id: String
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    var priceChange: Double {
        close - open
    }
    
    var isPositive: Bool {
        close >= open
    }
}