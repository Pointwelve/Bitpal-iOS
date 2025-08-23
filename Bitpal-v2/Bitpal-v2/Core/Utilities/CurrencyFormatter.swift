//
//  CurrencyFormatter.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 21/7/25.
//

import Foundation

struct CurrencyFormatter {
    
    // MARK: - Currency Formatting
    
    static func formatCurrencyEnhanced(_ value: Double, code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        
        // Adaptive precision based on value range
        if value < 0.01 {
            formatter.minimumFractionDigits = 6
            formatter.maximumFractionDigits = 8
        } else if value < 1.0 {
            formatter.minimumFractionDigits = 4
            formatter.maximumFractionDigits = 6
        } else if value < 100.0 {
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 4
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 3
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
    
    // MARK: - Compact Price Formatting (for main display)
    
    static func formatPriceCompact(_ value: Double, code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.usesGroupingSeparator = true // Add thousands separators
        
        // Smart decimal formatting without abbreviations
        if value < 0.01 {
            // For very small values, show more decimals
            formatter.minimumFractionDigits = 4
            formatter.maximumFractionDigits = 6
        } else if value < 1.0 {
            // For values under $1, show 3-4 decimals
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 4
        } else if value < 100.0 {
            // For values under $100, show 2-3 decimals
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 3
        } else {
            // For larger values, show 2 decimals max with thousands separators
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
    
    // MARK: - Volume Formatting
    
    static func formatVolume(_ volume: Double) -> String {
        if volume > 1_000_000_000 {
            return String(format: "%.2fB", volume / 1_000_000_000)
        } else if volume > 1_000_000 {
            return String(format: "%.2fM", volume / 1_000_000)
        } else if volume > 1_000 {
            return String(format: "%.2fK", volume / 1_000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
    
    // MARK: - Percentage Formatting
    
    static func formatPercentage(_ value: Double, precision: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        
        return formatter.string(from: NSNumber(value: value / 100)) ?? "\(String(format: "%.2f", value))%"
    }
    
    // MARK: - Price Change Formatting
    
    static func formatPriceChange(_ value: Double, withSign: Bool = true) -> String {
        let prefix = withSign ? (value >= 0 ? "+" : "") : ""
        return prefix + formatCurrencyEnhanced(abs(value))
    }
}

// MARK: - NumberFormatter Extensions

extension NumberFormatter {
    static let supplyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        formatter.roundingMode = .halfUp
        return formatter
    }()
}