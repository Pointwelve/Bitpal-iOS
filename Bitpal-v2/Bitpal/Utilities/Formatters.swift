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
    // MARK: - Currency Formatter

    /// USD currency formatter (e.g., "$45,000.50")
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Compact currency formatter for large numbers (e.g., "$45K", "$1.2M", "$3.5B")
    /// Note: Uses custom compact formatting since NumberFormatter.notation is not available
    static let compactCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    // MARK: - Percentage Formatter

    /// Percentage formatter (e.g., "+2.5%", "-3.2%")
    static let percentage: NumberFormatter = {
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
    static let compactPercentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        formatter.multiplier = 1
        return formatter
    }()

    // MARK: - Helper Methods

    /// Format Decimal as USD currency string
    static func formatCurrency(_ value: Decimal) -> String {
        currency.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    /// Format Decimal as compact USD currency string (e.g., "$45K", "$1.2M", "$3.5B")
    static func formatCompactCurrency(_ value: Decimal) -> String {
        let doubleValue = (value as NSDecimalNumber).doubleValue
        let absValue = abs(doubleValue)

        let formatted: String
        if absValue >= 1_000_000_000 {
            formatted = String(format: "$%.1fB", doubleValue / 1_000_000_000)
        } else if absValue >= 1_000_000 {
            formatted = String(format: "$%.1fM", doubleValue / 1_000_000)
        } else if absValue >= 1_000 {
            formatted = String(format: "$%.1fK", doubleValue / 1_000)
        } else {
            formatted = compactCurrency.string(from: value as NSDecimalNumber) ?? "$0"
        }

        return formatted
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
