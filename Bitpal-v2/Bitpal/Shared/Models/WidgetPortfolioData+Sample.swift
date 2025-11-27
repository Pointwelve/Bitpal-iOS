//
//  WidgetPortfolioData+Sample.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import Foundation

// MARK: - Sample Data for Widget Previews

extension WidgetPortfolioData {
    /// Sample data for widget previews and placeholders
    /// Represents a typical portfolio with mixed P&L
    static let sample = WidgetPortfolioData(
        totalValue: Decimal(125000.50),
        unrealizedPnL: Decimal(15000.00),
        realizedPnL: Decimal(5000.00),
        totalPnL: Decimal(20000.00),
        holdings: WidgetHolding.sampleHoldings,
        lastUpdated: Date()
    )

    /// Sample data representing an empty portfolio
    /// For testing empty state in widgets
    static let empty = WidgetPortfolioData(
        totalValue: 0,
        unrealizedPnL: 0,
        realizedPnL: 0,
        totalPnL: 0,
        holdings: [],
        lastUpdated: Date()
    )

    /// Sample data with only realized P&L (all positions closed)
    /// For testing closed-positions-only state
    static let closedOnly = WidgetPortfolioData(
        totalValue: 0,
        unrealizedPnL: 0,
        realizedPnL: Decimal(8500.00),
        totalPnL: Decimal(8500.00),
        holdings: [],
        lastUpdated: Date()
    )

    /// Sample data with stale timestamp (2 hours ago)
    /// For testing staleness indicator
    static let stale = WidgetPortfolioData(
        totalValue: Decimal(125000.50),
        unrealizedPnL: Decimal(15000.00),
        realizedPnL: Decimal(5000.00),
        totalPnL: Decimal(20000.00),
        holdings: WidgetHolding.sampleHoldings,
        lastUpdated: Date().addingTimeInterval(-7200) // 2 hours ago
    )

    /// Sample with single holding
    /// For testing minimal portfolio display
    static let singleHolding = WidgetPortfolioData(
        totalValue: Decimal(50000.00),
        unrealizedPnL: Decimal(5000.00),
        realizedPnL: 0,
        totalPnL: Decimal(5000.00),
        holdings: [WidgetHolding.sampleHoldings[0]],
        lastUpdated: Date()
    )

    /// Sample with two holdings
    /// For testing medium widget display
    static let twoHoldings = WidgetPortfolioData(
        totalValue: Decimal(80000.00),
        unrealizedPnL: Decimal(8000.00),
        realizedPnL: Decimal(2000.00),
        totalPnL: Decimal(10000.00),
        holdings: Array(WidgetHolding.sampleHoldings.prefix(2)),
        lastUpdated: Date()
    )

    /// Sample with negative P&L
    /// For testing loss state display (red colors)
    static let negative = WidgetPortfolioData(
        totalValue: Decimal(75000.00),
        unrealizedPnL: Decimal(-12000.00),
        realizedPnL: Decimal(-3000.00),
        totalPnL: Decimal(-15000.00),
        holdings: WidgetHolding.sampleLossHoldings,
        lastUpdated: Date()
    )
}

// MARK: - Sample Holdings

extension WidgetHolding {
    /// Sample holdings for widget previews (profit state)
    static let sampleHoldings: [WidgetHolding] = [
        WidgetHolding(
            id: "bitcoin",
            symbol: "BTC",
            name: "Bitcoin",
            currentValue: Decimal(100000.00),
            pnlAmount: Decimal(12000.00),
            pnlPercentage: Decimal(13.64)
        ),
        WidgetHolding(
            id: "ethereum",
            symbol: "ETH",
            name: "Ethereum",
            currentValue: Decimal(15000.00),
            pnlAmount: Decimal(2000.00),
            pnlPercentage: Decimal(15.38)
        ),
        WidgetHolding(
            id: "solana",
            symbol: "SOL",
            name: "Solana",
            currentValue: Decimal(5000.00),
            pnlAmount: Decimal(500.00),
            pnlPercentage: Decimal(11.11)
        ),
        WidgetHolding(
            id: "cardano",
            symbol: "ADA",
            name: "Cardano",
            currentValue: Decimal(3000.00),
            pnlAmount: Decimal(300.00),
            pnlPercentage: Decimal(11.11)
        ),
        WidgetHolding(
            id: "polkadot",
            symbol: "DOT",
            name: "Polkadot",
            currentValue: Decimal(2000.50),
            pnlAmount: Decimal(200.00),
            pnlPercentage: Decimal(11.10)
        )
    ]

    /// Sample holdings for loss state previews
    static let sampleLossHoldings: [WidgetHolding] = [
        WidgetHolding(
            id: "bitcoin",
            symbol: "BTC",
            name: "Bitcoin",
            currentValue: Decimal(60000.00),
            pnlAmount: Decimal(-8000.00),
            pnlPercentage: Decimal(-11.76)
        ),
        WidgetHolding(
            id: "ethereum",
            symbol: "ETH",
            name: "Ethereum",
            currentValue: Decimal(10000.00),
            pnlAmount: Decimal(-3000.00),
            pnlPercentage: Decimal(-23.08)
        ),
        WidgetHolding(
            id: "solana",
            symbol: "SOL",
            name: "Solana",
            currentValue: Decimal(5000.00),
            pnlAmount: Decimal(-1000.00),
            pnlPercentage: Decimal(-16.67)
        )
    ]
}
