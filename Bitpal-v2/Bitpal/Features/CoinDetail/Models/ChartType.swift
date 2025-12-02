//
//  ChartType.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation

/// Chart visualization type
enum ChartType: String, CaseIterable, Identifiable, Codable {
    case line = "Line"
    case candle = "Candle"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// SF Symbol name for the chart type
    var iconName: String {
        switch self {
        case .line: return "chart.xyaxis.line"
        case .candle: return "chart.bar.fill"
        }
    }

    /// Human-readable label
    var displayName: String { rawValue }

    /// Accessibility description
    var accessibilityLabel: String {
        switch self {
        case .line: return "Line chart"
        case .candle: return "Candlestick chart"
        }
    }

    // MARK: - Available Time Ranges

    /// Time ranges available for this chart type
    var availableRanges: [ChartTimeRange] {
        switch self {
        case .line: return ChartTimeRange.lineRanges
        case .candle: return ChartTimeRange.candleRanges
        }
    }

    /// Check if a time range is available for this chart type
    func isRangeAvailable(_ range: ChartTimeRange) -> Bool {
        availableRanges.contains(range)
    }

    /// Find closest available range when switching chart types
    func closestAvailableRange(to range: ChartTimeRange) -> ChartTimeRange {
        if isRangeAvailable(range) {
            return range
        }

        // Find closest match for unavailable short ranges
        switch range {
        case .fifteenMinutes, .fourHours:
            return .oneHour  // Closest to unavailable short ranges
        default:
            return availableRanges.first ?? .oneDay
        }
    }

    // MARK: - Persistence

    /// UserDefaults key for chart type preference
    private static let preferenceKey = "chartTypePreference"

    /// Save preferred chart type
    func saveAsPreference() {
        UserDefaults.standard.set(rawValue, forKey: Self.preferenceKey)
    }

    /// Load preferred chart type (defaults to .line)
    static func loadPreference() -> ChartType {
        guard let rawValue = UserDefaults.standard.string(forKey: preferenceKey),
              let chartType = ChartType(rawValue: rawValue) else {
            return .line  // Default for new users
        }
        return chartType
    }
}
