//
//  PortfolioSummaryView.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-23.
//  Closed Positions feature (003-closed-positions) - T032-T036
//

import SwiftUI

/// Portfolio summary card showing total value and P&L metrics
/// Per Constitution Principle II: Uses Liquid Glass design
/// Per US2: Displays unrealized, realized, and total P&L
struct PortfolioSummaryView: View {
    let summary: PortfolioSummary
    let onRealizedPnLTap: () -> Void

    var body: some View {
        LiquidGlassCard {
            VStack(spacing: Spacing.standard) {
                // Total Value (primary metric)
                VStack(spacing: Spacing.tiny) {
                    Text("Total Value")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                    Text(Formatters.formatCurrency(summary.totalValue))
                        .font(Typography.largeTitle)
                        .fontWeight(.bold)
                }

                Divider()

                // T033: Unrealized P&L (open positions)
                summaryRow(
                    label: "Unrealized P&L",
                    value: summary.unrealizedPnL,
                    color: pnlColor(summary.unrealizedPnL),
                    isBold: false
                )

                // T034: Realized P&L (closed positions) - tappable
                Button {
                    onRealizedPnLTap()
                } label: {
                    summaryRow(
                        label: "Realized P&L",
                        value: summary.realizedPnL,
                        color: pnlColor(summary.realizedPnL),
                        isBold: false
                    )
                }
                .buttonStyle(.plain)

                // T035: Divider before total
                Divider()

                // T036: Total P&L (sum of unrealized + realized) - bold
                summaryRow(
                    label: "Total P&L",
                    value: summary.totalPnL,
                    color: pnlColor(summary.totalPnL),
                    isBold: true
                )
            }
        }
    }

    // MARK: - Components

    /// Summary row displaying label and value with color coding
    private func summaryRow(label: String, value: Decimal, color: Color, isBold: Bool) -> some View {
        HStack {
            Text(label)
                .font(isBold ? Typography.title3 : Typography.body)
                .foregroundColor(.textPrimary)

            Spacer()

            Text(formatProfitLoss(value))
                .font(isBold ? Typography.title2 : Typography.headline)
                .fontWeight(isBold ? .bold : .medium)
                .foregroundColor(color)
        }
    }

    // MARK: - Helpers

    /// Color for P&L values (green for positive, red for negative, neutral for zero)
    private func pnlColor(_ value: Decimal) -> Color {
        if value > 0 {
            return .profitGreen
        } else if value < 0 {
            return .lossRed
        } else {
            return .textSecondary
        }
    }

    /// Format P&L with sign prefix
    private func formatProfitLoss(_ value: Decimal) -> String {
        let prefix = value > 0 ? "+" : ""
        return prefix + Formatters.formatCurrency(value)
    }
}

#Preview("Profitable Portfolio") {
    let summary = PortfolioSummary(
        totalValue: 127456.89,
        unrealizedPnL: 15234.50,  // Open positions profit
        realizedPnL: 8221.39,     // Closed positions profit
        totalOpenCost: 112222.39,
        totalClosedCost: 32000.00
    )

    return PortfolioSummaryView(summary: summary) {
        print("Tapped Realized P&L")
    }
    .padding()
}

#Preview("Mixed Performance") {
    let summary = PortfolioSummary(
        totalValue: 95000.00,
        unrealizedPnL: -5000.00,  // Open positions loss
        realizedPnL: 12000.00,    // Closed positions profit
        totalOpenCost: 100000.00,
        totalClosedCost: 40000.00
    )

    return PortfolioSummaryView(summary: summary) {
        print("Tapped Realized P&L")
    }
    .padding()
}

#Preview("Only Closed Positions") {
    let summary = PortfolioSummary(
        totalValue: 0,            // No open holdings
        unrealizedPnL: 0,         // No open P&L
        realizedPnL: 15000.00,    // Only closed profit
        totalOpenCost: 0,
        totalClosedCost: 50000.00
    )

    return PortfolioSummaryView(summary: summary) {
        print("Tapped Realized P&L")
    }
    .padding()
}
