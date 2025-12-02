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
        case .oneYear: return "1 year"
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
        case .oneYear:
            return "365"
        }
    }

    /// Maximum data points to display for performance
    var maxDataPoints: Int {
        switch self {
        case .fifteenMinutes: return 15
        case .oneHour: return 60
        case .fourHours: return 48
        case .oneDay: return 96
        case .oneWeek: return 42
        case .oneMonth: return 30
        case .oneYear: return 52
        }
    }

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
        case .oneYear:
            return 3600        // 1 hour
        }
    }

    /// Cache key suffix for this range
    var cacheKeySuffix: String { rawValue }

    // MARK: - Chart Type Availability

    /// Time ranges available for line charts (simpler, 5 options)
    static var lineRanges: [ChartTimeRange] {
        [.oneHour, .oneDay, .oneWeek, .oneMonth, .oneYear]
    }

    /// Time ranges available for candlestick charts (all 7 options)
    static var candleRanges: [ChartTimeRange] {
        allCases
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
        case .oneYear:
            cutoffDate = now.addingTimeInterval(-365 * 24 * 60 * 60)
        }

        return points.filter { $0[keyPath: timestampKeyPath] >= cutoffDate }
    }
}
