//
//  MediumWidgetView.swift
//  BitpalWidget
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import SwiftUI
import WidgetKit

/// Medium widget view displaying portfolio value, P&L breakdown, and top 2 holdings.
/// Per FR-002: Shows total value, unrealized P&L, realized P&L, top 2 holdings.
/// Per FR-009: Color coding - green for profit, red for loss.
/// Per FR-010: Deep link to Portfolio tab when tapped.
struct MediumWidgetView: View {
    let entry: PortfolioEntry

    /// Maximum holdings to display in medium widget
    private let maxHoldings = 2

    var body: some View {
        if let data = entry.data, !data.isEmpty {
            portfolioContent(data: data)
        } else {
            emptyStateContent
        }
    }

    // MARK: - Portfolio Content

    @ViewBuilder
    private func portfolioContent(data: WidgetPortfolioData) -> some View {
        Link(destination: URL(string: "bitpal://portfolio")!) {
            HStack(spacing: 16) {
                // Left side: Value and P&L breakdown
                VStack(alignment: .leading, spacing: 6) {
                    // Header with stale indicator
                    HStack {
                        Text("Portfolio")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if data.isStale {
                            Image(systemName: "exclamationmark.circle")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }

                    // Total Value
                    Text(formatCurrency(data.totalValue))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    // P&L Breakdown
                    VStack(alignment: .leading, spacing: 2) {
                        // Unrealized P&L
                        HStack(spacing: 4) {
                            Text("Unrealized:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatPnL(data.unrealizedPnL))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(pnlColor(data.unrealizedPnL))
                        }

                        // Realized P&L
                        HStack(spacing: 4) {
                            Text("Realized:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(formatPnL(data.realizedPnL))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(pnlColor(data.realizedPnL))
                        }
                    }

                    Spacer()

                    // Last Updated - auto-updating relative date
                    HStack(spacing: 4) {
                        Text("Updated")
                        Text(data.lastUpdated, style: .relative)
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }

                // Divider
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)

                // Right side: Top holdings
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Holdings")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if data.holdings.isEmpty {
                        Text("No holdings")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(data.holdings.prefix(maxHoldings)) { holding in
                            HoldingRowView(holding: holding)
                        }

                        // Show remaining count if more than 2 holdings
                        if data.holdings.count > maxHoldings {
                            Text("+\(data.holdings.count - maxHoldings) more")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Empty State

    /// T033: Empty state with graceful handling for 0-1 holdings
    @ViewBuilder
    private var emptyStateContent: some View {
        Link(destination: URL(string: "bitpal://portfolio")!) {
            HStack(spacing: 16) {
                // Left side
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("Add holdings to see\nyour portfolio here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2

        let doubleValue = NSDecimalNumber(decimal: value).doubleValue

        if abs(doubleValue) >= 100_000 {
            if abs(doubleValue) >= 1_000_000 {
                let millions = doubleValue / 1_000_000
                return String(format: "$%.1fM", millions)
            } else {
                let thousands = doubleValue / 1_000
                return String(format: "$%.0fK", thousands)
            }
        }

        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
    }

    private func formatPnL(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0"
    }

    private func pnlColor(_ value: Decimal) -> Color {
        if value > 0 {
            return .green
        } else if value < 0 {
            return .red
        } else {
            return .secondary
        }
    }

}

// MARK: - Previews

#Preview("With Data") {
    MediumWidgetView(entry: .snapshot())
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Empty") {
    MediumWidgetView(entry: .empty())
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Single Holding") {
    MediumWidgetView(entry: PortfolioEntry(date: Date(), data: .singleHolding))
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Two Holdings") {
    MediumWidgetView(entry: PortfolioEntry(date: Date(), data: .twoHoldings))
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Negative P&L") {
    MediumWidgetView(entry: PortfolioEntry(date: Date(), data: .negative))
        .containerBackground(.fill.tertiary, for: .widget)
}
