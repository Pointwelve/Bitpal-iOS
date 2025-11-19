//
//  HoldingRowView.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import SwiftUI

/// Individual holding display row
/// Per Constitution Principle II: Uses LiquidGlassCard
/// Per Constitution Principle I: Equatable for performance optimization (T032)
struct HoldingRowView: View, Equatable {
    let holding: Holding

    static func == (lhs: HoldingRowView, rhs: HoldingRowView) -> Bool {
        lhs.holding == rhs.holding
    }

    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Header: Coin name and symbol
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text(holding.coin.name)
                            .font(Typography.headline)
                        Text(holding.coin.symbol.uppercased())
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    // Current value
                    Text(Formatters.formatCurrency(holding.currentValue))
                        .font(Typography.headline)
                }

                Divider()

                // Details grid
                HStack {
                    // Quantity
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text("Quantity")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(formatQuantity(holding.totalAmount))
                            .font(Typography.body)
                    }

                    Spacer()

                    // Avg Cost
                    VStack(alignment: .center, spacing: Spacing.tiny) {
                        Text("Avg Cost")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(Formatters.formatCurrency(holding.avgCost))
                            .font(Typography.body)
                    }

                    Spacer()

                    // P&L (FR-011: color coding)
                    VStack(alignment: .trailing, spacing: Spacing.tiny) {
                        Text("P&L")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatProfitLoss(holding.profitLoss))
                                .font(Typography.body)
                                .foregroundColor(profitLossColor)
                            Text(formatPercentage(holding.profitLossPercentage))
                                .font(Typography.caption)
                                .foregroundColor(profitLossColor)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Color for P&L display
    /// Per FR-011: green for positive, red for negative, neutral for zero
    private var profitLossColor: Color {
        if holding.profitLoss > 0 {
            return .profitGreen
        } else if holding.profitLoss < 0 {
            return .lossRed
        } else {
            return .textSecondary
        }
    }

    /// Format quantity with appropriate precision
    private func formatQuantity(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8

        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    /// Format P&L with sign
    private func formatProfitLoss(_ value: Decimal) -> String {
        let prefix = value > 0 ? "+" : ""
        return prefix + Formatters.formatCurrency(value)
    }

    /// Format percentage with 2 decimal places (FR-026)
    private func formatPercentage(_ value: Decimal) -> String {
        let prefix = value > 0 ? "+" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let formatted = formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
        return "\(prefix)\(formatted)%"
    }
}

#Preview {
    let coin = Coin(
        id: "bitcoin",
        symbol: "btc",
        name: "Bitcoin",
        currentPrice: 50000,
        priceChange24h: 2.5,
        lastUpdated: Date(),
        marketCap: nil
    )

    let holding = Holding(
        id: "bitcoin",
        coin: coin,
        totalAmount: Decimal(string: "1.5")!,
        avgCost: 40000,
        currentValue: 75000
    )

    return HoldingRowView(holding: holding)
        .padding()
}
