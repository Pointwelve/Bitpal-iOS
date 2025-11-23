//
//  ClosedPositionRowView.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-23.
//  Closed Positions feature (003-closed-positions) - T021
//

import SwiftUI

/// Individual closed position display row
/// Per Constitution Principle II: Uses LiquidGlassCard
/// Per Constitution Principle I: Equatable for performance optimization
struct ClosedPositionRowView: View, Equatable {
    let closedPosition: ClosedPosition

    static func == (lhs: ClosedPositionRowView, rhs: ClosedPositionRowView) -> Bool {
        lhs.closedPosition == rhs.closedPosition
    }

    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Header: Coin name, symbol, and close date
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text(closedPosition.coin.name)
                            .font(Typography.headline)
                        Text(closedPosition.coin.symbol.uppercased())
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Text(formatDate(closedPosition.closedDate))
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()

                // Metrics: Quantity, Avg Cost, Avg Sale, Realized P&L
                VStack(spacing: Spacing.small) {
                    // Row 1: Quantity and Avg Cost
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.tiny) {
                            Text("Quantity")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            Text(formatQuantity(closedPosition.totalQuantity))
                                .font(Typography.body)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: Spacing.tiny) {
                            Text("Avg Cost")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            Text(Formatters.formatCurrency(closedPosition.avgCostPrice))
                                .font(Typography.body)
                        }
                    }

                    // Row 2: Avg Sale and Realized P&L
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.tiny) {
                            Text("Avg Sale")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            Text(Formatters.formatCurrency(closedPosition.avgSalePrice))
                                .font(Typography.body)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: Spacing.tiny) {
                            Text("Realized P&L")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatProfitLoss(closedPosition.realizedPnL))
                                    .font(Typography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(profitLossColor)
                                Text(formatPercentage(closedPosition.realizedPnLPercentage))
                                    .font(Typography.caption)
                                    .foregroundColor(profitLossColor)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Color for P&L display
    /// Per FR-003: green for positive gains, red for losses
    private var profitLossColor: Color {
        if closedPosition.realizedPnL > 0 {
            return .profitGreen
        } else if closedPosition.realizedPnL < 0 {
            return .lossRed
        } else {
            return .textSecondary
        }
    }

    /// Format close date (e.g., "Jan 15, 2025")
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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

    let closedPosition = ClosedPosition(
        id: UUID(),
        coinId: "bitcoin",
        coin: coin,
        totalQuantity: Decimal(string: "1.0")!,
        avgCostPrice: 40000,
        avgSalePrice: 50000,
        closedDate: Date(),
        cycleTransactions: []
    )

    return ClosedPositionRowView(closedPosition: closedPosition)
        .padding()
}
