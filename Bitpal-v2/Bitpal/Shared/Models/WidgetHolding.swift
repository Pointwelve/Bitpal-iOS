//
//  WidgetHolding.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import Foundation

/// Lightweight holding data for widget display.
/// Subset of Holding properties needed for widget UI.
/// Per Constitution Principle IV: Uses Decimal for all financial values.
struct WidgetHolding: Codable, Identifiable, Equatable, Sendable {
    // MARK: - Identification

    /// CoinGecko coin ID (e.g., "bitcoin")
    let id: String

    /// Ticker symbol uppercase (e.g., "BTC")
    let symbol: String

    /// Full coin name (e.g., "Bitcoin")
    let name: String

    // MARK: - Value

    /// Current market value in USD
    let currentValue: Decimal

    // MARK: - P&L

    /// Unrealized profit/loss amount in USD
    let pnlAmount: Decimal

    /// Unrealized profit/loss as percentage
    let pnlPercentage: Decimal

    // MARK: - Computed

    /// True if holding is profitable (green), false if loss (red)
    var isProfit: Bool {
        pnlAmount >= 0
    }
}

