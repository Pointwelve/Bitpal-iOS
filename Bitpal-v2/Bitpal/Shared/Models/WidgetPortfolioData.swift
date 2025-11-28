//
//  WidgetPortfolioData.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import Foundation

/// Lightweight portfolio data optimized for widget display.
/// Written by main app on each portfolio update.
/// Read by widget during timeline generation.
/// Per Constitution Principle IV: Uses Decimal for all financial values.
struct WidgetPortfolioData: Codable, Equatable, Sendable {
    // MARK: - Portfolio Value

    /// Total current value of all open holdings (USD)
    let totalValue: Decimal

    // MARK: - P&L Breakdown

    /// Unrealized P&L from open positions (USD)
    let unrealizedPnL: Decimal

    /// Realized P&L from closed positions (USD)
    let realizedPnL: Decimal

    /// Total P&L (unrealized + realized) in USD
    let totalPnL: Decimal

    // MARK: - Holdings

    /// Top holdings by current value (max 5)
    /// Pre-sorted by currentValue descending
    let holdings: [WidgetHolding]

    // MARK: - Metadata

    /// Timestamp when this data was generated
    let lastUpdated: Date

    // MARK: - Computed Properties

    /// Whether portfolio has any holdings
    var isEmpty: Bool {
        holdings.isEmpty && totalValue == 0
    }

    /// Whether data is stale (> 60 minutes old)
    /// Per FR-016: Show staleness indicator when > 60 minutes
    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 3600 // 60 minutes
    }

    /// Minutes since last update
    var minutesSinceUpdate: Int {
        Int(Date().timeIntervalSince(lastUpdated) / 60)
    }
}

// MARK: - Validation

extension WidgetPortfolioData {
    /// Maximum number of holdings stored for widget display
    static let maxHoldings = 5

    /// Validates that the data meets widget requirements
    var isValid: Bool {
        holdings.count <= Self.maxHoldings
    }
}
