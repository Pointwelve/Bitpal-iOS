//
//  LargeWidgetView.swift
//  BitpalWidget
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import SwiftUI
import WidgetKit

/// Large widget view displaying full P&L breakdown and top 5 holdings.
/// Per FR-003: Shows total value, unrealized P&L, realized P&L, total P&L, top 5 holdings.
/// Per FR-003: Holdings show symbol, name, current value, P&L amount, P&L percentage.
/// Per FR-009: Color coding - green for profit, red for loss.
/// Per FR-010: Deep link to Portfolio tab when tapped.
struct LargeWidgetView: View {
    let entry: PortfolioEntry

    /// Maximum holdings to display in large widget
    private let maxHoldings = 5

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
            VStack(alignment: .leading, spacing: 12) {
                // Header Section
                headerSection(data: data)

                // P&L Breakdown Section
                pnlBreakdownSection(data: data)

                Divider()
                    .background(.quaternary)

                // Holdings Section
                holdingsSection(data: data)

                Spacer()

                // Footer with last updated
                footerSection(data: data)
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(data: WidgetPortfolioData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Portfolio")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    if data.isStale {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Text(formatCurrency(data.totalValue))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Total P&L Badge
            VStack(alignment: .trailing, spacing: 2) {
                Text("Total P&L")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatPnL(data.totalPnL))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(pnlColor(data.totalPnL))
            }
        }
    }

    // MARK: - P&L Breakdown Section

    @ViewBuilder
    private func pnlBreakdownSection(data: WidgetPortfolioData) -> some View {
        HStack(spacing: 16) {
            // Unrealized P&L
            VStack(alignment: .leading, spacing: 2) {
                Text("Unrealized")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatPnL(data.unrealizedPnL))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(pnlColor(data.unrealizedPnL))
            }

            // Realized P&L
            VStack(alignment: .leading, spacing: 2) {
                Text("Realized")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formatPnL(data.realizedPnL))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(pnlColor(data.realizedPnL))
            }

            Spacer()
        }
    }

    // MARK: - Holdings Section

    @ViewBuilder
    private func holdingsSection(data: WidgetPortfolioData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Holdings")
                .font(.caption)
                .foregroundStyle(.secondary)

            if data.holdings.isEmpty {
                Text("No holdings yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                // T041: No empty rows - only show actual holdings
                ForEach(data.holdings.prefix(maxHoldings)) { holding in
                    HoldingRowView(holding: holding, showPercentage: true)
                }

                // Show remaining count if more than 5 holdings
                if data.holdings.count > maxHoldings {
                    Text("+\(data.holdings.count - maxHoldings) more holdings")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Footer Section

    @ViewBuilder
    private func footerSection(data: WidgetPortfolioData) -> some View {
        // Last Updated - auto-updating relative date
        HStack(spacing: 4) {
            Text("Updated")
            Text(data.lastUpdated, style: .relative)
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Empty State

    /// T041: Empty state with graceful handling for <5 holdings
    @ViewBuilder
    private var emptyStateContent: some View {
        Link(destination: URL(string: "bitpal://portfolio")!) {
            VStack(spacing: 16) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    Text("No Portfolio Data")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Add your first transaction in the app\nto see your portfolio here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
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

        if abs(doubleValue) >= 1_000_000 {
            let millions = doubleValue / 1_000_000
            return String(format: "$%.2fM", millions)
        } else if abs(doubleValue) >= 100_000 {
            let thousands = doubleValue / 1_000
            return String(format: "$%.1fK", thousands)
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
    LargeWidgetView(entry: .snapshot())
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Empty") {
    LargeWidgetView(entry: .empty())
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Single Holding") {
    LargeWidgetView(entry: PortfolioEntry(date: Date(), data: .singleHolding))
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Three Holdings") {
    LargeWidgetView(entry: PortfolioEntry(date: Date(), data: WidgetPortfolioData(
        totalValue: 95000,
        unrealizedPnL: 10000,
        realizedPnL: 3000,
        totalPnL: 13000,
        holdings: Array(WidgetHolding.sampleHoldings.prefix(3)),
        lastUpdated: Date()
    )))
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Full (5 Holdings)") {
    LargeWidgetView(entry: .snapshot())
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Negative P&L") {
    LargeWidgetView(entry: PortfolioEntry(date: Date(), data: .negative))
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Stale Data") {
    LargeWidgetView(entry: PortfolioEntry(date: Date(), data: .stale))
        .containerBackground(.fill.tertiary, for: .widget)
}

#Preview("Closed Only") {
    LargeWidgetView(entry: PortfolioEntry(date: Date(), data: .closedOnly))
        .containerBackground(.fill.tertiary, for: .widget)
}
