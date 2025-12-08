//
//  ChartTimeRange.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// Available time ranges for price charts
enum ChartTimeRange: String, CaseIterable, Identifiable, Codable {
    case fifteenMinutes = "15M"
    case oneHour = "1H"
    case fourHours = "4H"
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case sixMonths = "6M"
    case oneYear = "1Y"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// Human-readable label
    var displayName: String { rawValue }

    /// Full description for accessibility
    var accessibilityLabel: String {
        switch self {
        case .fifteenMinutes: return "15 minutes"
        case .oneHour: return "1 hour"
        case .fourHours: return "4 hours"
        case .oneDay: return "1 day"
        case .oneWeek: return "1 week"
        case .oneMonth: return "1 month"
        case .sixMonths: return "6 months"
        case .oneYear: return "1 year"
        }
    }

    /// Display name for candlestick charts (shows candle interval, not time range)
    var candleDisplayName: String {
        switch self {
        case .oneDay: return "30M"      // 30-minute candles
        case .oneWeek: return "4H"      // 4-hour candles
        case .sixMonths: return "4D"    // 4-day candles
        default: return displayName     // Fallback for other cases
        }
    }

    // MARK: - API Mapping

    /// CoinGecko API `days` parameter value
    var apiDays: String {
        switch self {
        case .fifteenMinutes, .oneHour, .fourHours, .oneDay:
            return "1"
        case .oneWeek:
            return "7"
        case .oneMonth:
            return "30"
        case .sixMonths:
            return "180"
        case .oneYear:
            return "365"
        }
    }

    /// Maximum data points to display for performance (line charts)
    var maxDataPoints: Int {
        switch self {
        case .fifteenMinutes: return 15
        case .oneHour: return 60
        case .fourHours: return 48
        case .oneDay: return 96
        case .oneWeek: return 42
        case .oneMonth: return 30
        case .sixMonths: return 45
        case .oneYear: return 52
        }
    }

    /// Maximum candles to display for candlestick charts (consistent 42 for uniform UX)
    static var candleMaxDataPoints: Int { 42 }

    // MARK: - Caching

    /// Cache time-to-live in seconds
    var cacheTTL: TimeInterval {
        switch self {
        case .fifteenMinutes, .oneHour, .fourHours:
            return 60          // 1 minute
        case .oneDay:
            return 300         // 5 minutes
        case .oneWeek:
            return 900         // 15 minutes
        case .oneMonth:
            return 1800        // 30 minutes
        case .sixMonths, .oneYear:
            return 3600        // 1 hour
        }
    }

    /// Cache key suffix for this range
    var cacheKeySuffix: String { rawValue }

    /// Expected time span in seconds for limited history detection
    var expectedTimeSpan: TimeInterval {
        switch self {
        case .fifteenMinutes:
            return 15 * 60
        case .oneHour:
            return 60 * 60
        case .fourHours:
            return 4 * 60 * 60
        case .oneDay:
            return 24 * 60 * 60
        case .oneWeek:
            return 7 * 24 * 60 * 60
        case .oneMonth:
            return 30 * 24 * 60 * 60
        case .sixMonths:
            return 180 * 24 * 60 * 60
        case .oneYear:
            return 365 * 24 * 60 * 60
        }
    }

    // MARK: - Chart Type Availability

    /// Time ranges available for line charts (simpler, 5 options)
    static var lineRanges: [ChartTimeRange] {
        [.oneHour, .oneDay, .oneWeek, .oneMonth, .oneYear]
    }

    /// Time ranges available for candlestick charts (labeled by candle interval)
    /// - 30M: 1 day of 30-minute candles (days=1)
    /// - 4H: 1 week of 4-hour candles (days=7)
    /// - 4D: 6 months of 4-day candles (days=180)
    /// Note: CoinGecko OHLC API determines candle interval automatically based on days parameter
    static var candleRanges: [ChartTimeRange] {
        [.oneDay, .oneWeek, .sixMonths]
    }

    /// Default time range
    static var defaultRange: ChartTimeRange { .oneDay }

    // MARK: - Data Filtering

    /// Filter data points to match this time range
    func filterDataPoints<T>(_ points: [T], timestampKeyPath: KeyPath<T, Date>) -> [T] {
        let cutoffDate: Date
        let now = Date()

        switch self {
        case .fifteenMinutes:
            cutoffDate = now.addingTimeInterval(-15 * 60)
        case .oneHour:
            cutoffDate = now.addingTimeInterval(-60 * 60)
        case .fourHours:
            cutoffDate = now.addingTimeInterval(-4 * 60 * 60)
        case .oneDay:
            cutoffDate = now.addingTimeInterval(-24 * 60 * 60)
        case .oneWeek:
            cutoffDate = now.addingTimeInterval(-7 * 24 * 60 * 60)
        case .oneMonth:
            cutoffDate = now.addingTimeInterval(-30 * 24 * 60 * 60)
        case .sixMonths:
            cutoffDate = now.addingTimeInterval(-180 * 24 * 60 * 60)
        case .oneYear:
            cutoffDate = now.addingTimeInterval(-365 * 24 * 60 * 60)
        }

        return points.filter { $0[keyPath: timestampKeyPath] >= cutoffDate }
    }
}
