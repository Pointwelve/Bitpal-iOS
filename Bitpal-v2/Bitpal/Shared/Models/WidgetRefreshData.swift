//
//  WidgetRefreshData.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-12-11.
//  Feature: 008-widget-background-refresh
//

import Foundation

/// Stores the minimal data needed for widget to recalculate portfolio values with fresh prices.
/// Written by main app to App Group, read by widget during timeline refresh.
/// Per Constitution Principle IV: Uses Decimal for all financial values.
struct WidgetRefreshData: Codable, Equatable, Sendable {
    // MARK: - Holdings

    /// Array of holdings with quantities and costs for recalculation
    let holdings: [RefreshableHolding]

    // MARK: - Realized P&L

    /// Total realized P&L from closed positions (unchanged during widget refresh)
    let realizedPnL: Decimal

    // MARK: - Nested Types

    /// Individual holding data needed for P&L recalculation
    struct RefreshableHolding: Codable, Equatable, Sendable, Identifiable {
        /// CoinGecko coin ID (e.g., "bitcoin") - used for API request
        let coinId: String

        /// Trading symbol (e.g., "BTC") - for display
        let symbol: String

        /// Display name (e.g., "Bitcoin") - for display
        let name: String

        /// Total quantity held - for value calculation
        let quantity: Decimal

        /// Average cost per coin - for P&L calculation
        let avgCost: Decimal

        /// Identifiable conformance using coinId
        var id: String { coinId }
    }

    // MARK: - Computed Properties

    /// Whether there are any holdings to refresh
    var isEmpty: Bool {
        holdings.isEmpty
    }

    /// All coin IDs for batched API request
    var coinIds: [String] {
        holdings.map { $0.coinId }
    }
}

// MARK: - Factory Methods

extension WidgetRefreshData {
    /// Creates empty refresh data (no holdings)
    static var empty: WidgetRefreshData {
        WidgetRefreshData(holdings: [], realizedPnL: 0)
    }

    /// Sample data for testing and previews
    static var sample: WidgetRefreshData {
        WidgetRefreshData(
            holdings: [
                RefreshableHolding(
                    coinId: "bitcoin",
                    symbol: "BTC",
                    name: "Bitcoin",
                    quantity: Decimal(string: "1.5")!,
                    avgCost: Decimal(string: "40000")!
                ),
                RefreshableHolding(
                    coinId: "ethereum",
                    symbol: "ETH",
                    name: "Ethereum",
                    quantity: Decimal(string: "10.0")!,
                    avgCost: Decimal(string: "2500")!
                )
            ],
            realizedPnL: Decimal(string: "1500.50")!
        )
    }
}
