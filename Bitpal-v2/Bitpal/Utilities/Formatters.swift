//
//  Formatters.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation

/// Shared formatters for consistent number and currency display
/// Per Constitution Principle IV: Use proper number formatting for financial data
enum Formatters {

    // MARK: - Adaptive Decimal Tiers

    /// Determines adaptive decimal places based on value magnitude
    /// Used by both price and quantity formatting for consistency
    /// - >= 1: 2 decimals
    /// - >= 0.01: 4 decimals
    /// - >= 0.0001: 6 decimals
    /// - < 0.0001: 8 decimals
    private static func adaptiveMaxDecimals(for absValue: Double) -> Int {
        switch absValue {
        case _ where absValue >= 1: return 2
        case _ where absValue >= 0.01: return 4
        case _ where absValue >= 0.0001: return 6
        default: return 8
        }
    }

    // MARK: - Cached Formatters

    /// Currency formatters indexed by max decimal places
    private static let currencyFormatters: [Int: NumberFormatter] = {
        var formatters: [Int: NumberFormatter] = [:]
        for decimals in [2, 4, 6, 8] {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = decimals
            formatters[decimals] = formatter
        }
        return formatters
    }()

    /// Decimal formatters indexed by max decimal places
    private static let decimalFormatters: [Int: NumberFormatter] = {
        var formatters: [Int: NumberFormatter] = [:]
        for decimals in [2, 4, 6, 8] {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = decimals
            formatters[decimals] = formatter
        }
        return formatters
    }()

    /// Compact currency formatter for large numbers
    private static let compactCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Percentage formatter (e.g., "+2.5%", "-3.2%")
    private static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        formatter.multiplier = 1 // CoinGecko already returns percentages (not decimals)
        return formatter
    }()

    /// Compact percentage formatter (e.g., "+2.5%", "-3%")
    private static let compactPercentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        formatter.multiplier = 1
        return formatter
    }()

    // MARK: - Public Formatting Methods

    /// Format Decimal as USD currency string (fixed 2 decimal places)
    /// Use for totals, P&L, and aggregate values
    static func formatCurrency(_ value: Decimal) -> String {
        currencyFormatters[2]!.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    /// Format cryptocurrency price with adaptive decimal places
    /// Adjusts precision based on price magnitude to preserve meaningful changes
    static func formatPrice(_ value: Decimal) -> String {
        let absValue = abs((value as NSDecimalNumber).doubleValue)
        let decimals = adaptiveMaxDecimals(for: absValue)
        return currencyFormatters[decimals]!.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    /// Format cryptocurrency quantity with adaptive decimal places
    /// Adjusts precision based on quantity magnitude (mirrors price formatting)
    static func formatQuantity(_ value: Decimal) -> String {
        let absValue = abs((value as NSDecimalNumber).doubleValue)
        let decimals = adaptiveMaxDecimals(for: absValue)
        return decimalFormatters[decimals]!.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    /// Format Decimal as compact USD currency string (e.g., "$45K", "$1.2M", "$3.5B")
    static func formatCompactCurrency(_ value: Decimal) -> String {
        let doubleValue = (value as NSDecimalNumber).doubleValue
        let absValue = abs(doubleValue)

        if absValue >= 1_000_000_000 {
            return String(format: "$%.1fB", doubleValue / 1_000_000_000)
        } else if absValue >= 1_000_000 {
            return String(format: "$%.1fM", doubleValue / 1_000_000)
        } else if absValue >= 1_000 {
            return String(format: "$%.1fK", doubleValue / 1_000)
        } else {
            return compactCurrency.string(from: value as NSDecimalNumber) ?? "$0"
        }
    }

    /// Format Decimal as percentage string (e.g., "+2.5%", "-3.2%")
    static func formatPercentage(_ value: Decimal) -> String {
        percentage.string(from: value as NSDecimalNumber) ?? "0%"
    }

    /// Format Decimal as compact percentage string
    static func formatCompactPercentage(_ value: Decimal) -> String {
        compactPercentage.string(from: value as NSDecimalNumber) ?? "0%"
    }
}
