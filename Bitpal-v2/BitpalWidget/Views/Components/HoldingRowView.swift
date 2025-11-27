//
//  HoldingRowView.swift
//  BitpalWidget
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import SwiftUI

/// Reusable row view for displaying a single holding in widgets.
/// Used by both MediumWidgetView and LargeWidgetView.
/// Per FR-003: Shows symbol, name, current value, P&L amount, P&L percentage.
struct HoldingRowView: View {
    let holding: WidgetHolding

    /// Whether to show extended details (percentage)
    /// Medium widget: false (compact)
    /// Large widget: true (full details)
    var showPercentage: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // Coin info (left side)
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(holding.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Value and P&L (right side)
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(holding.currentValue))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(formatPnL(holding.pnlAmount))
                        .font(.caption2)
                        .foregroundStyle(pnlColor)

                    if showPercentage {
                        Text(formatPercentage(holding.pnlPercentage))
                            .font(.caption2)
                            .foregroundStyle(pnlColor.opacity(0.8))
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Per FR-009: Green for profit, red for loss
    private var pnlColor: Color {
        holding.isProfit ? .green : .red
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0"
    }

    private func formatPnL(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0"
    }

    private func formatPercentage(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        let sign = doubleValue >= 0 ? "+" : ""
        return "(\(sign)\(String(format: "%.1f", doubleValue))%)"
    }
}

// MARK: - Previews

#Preview("Holding Row - Profit") {
    HoldingRowView(holding: WidgetHolding.sampleHoldings[0])
        .padding()
        .background(.regularMaterial)
}

#Preview("Holding Row - Loss") {
    HoldingRowView(holding: WidgetHolding.sampleLossHoldings[0], showPercentage: true)
        .padding()
        .background(.regularMaterial)
}

#Preview("Holding Row - With Percentage") {
    HoldingRowView(holding: WidgetHolding.sampleHoldings[1], showPercentage: true)
        .padding()
        .background(.regularMaterial)
}
