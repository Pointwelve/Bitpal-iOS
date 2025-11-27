//
//  SmallWidgetView.swift
//  BitpalWidget
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import SwiftUI
import WidgetKit

/// Small widget view displaying total portfolio value and P&L.
/// Per FR-001: Shows total portfolio value, total P&L amount, P&L percentage.
/// Per FR-009: Color coding - green for profit, red for loss.
/// Per FR-010: Deep link to Portfolio tab when tapped.
struct SmallWidgetView: View {
    let entry: PortfolioEntry

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
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("Portfolio")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if data.isStale {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                // Total Value
                Text(formatCurrency(data.totalValue))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                // Total P&L
                HStack(spacing: 4) {
                    Text(formatPnL(data.totalPnL))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(pnlColor(data.totalPnL))

                    Text(formatPnLPercentage(data.totalPnL, totalValue: data.totalValue))
                        .font(.caption)
                        .foregroundStyle(pnlColor(data.totalPnL).opacity(0.8))
                }

                // Last Updated - auto-updating relative date
                HStack(spacing: 4) {
                    Text("Updated")
                    Text(data.lastUpdated, style: .relative)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Empty State

    /// T022: Empty state showing "Add holdings" message
    @ViewBuilder
    private var emptyStateContent: some View {
        Link(destination: URL(string: "bitpal://portfolio")!) {
            VStack(spacing: 12) {
                Image(systemName: "chart.pie")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("Add holdings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Formatting Helpers

    /// Format currency value with compact notation for large values
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2

        let doubleValue = NSDecimalNumber(decimal: value).doubleValue

        // Use compact notation for values >= 100K
        if abs(doubleValue) >= 100_000 {
            formatter.numberStyle = .currencyAccounting
            formatter.maximumFractionDigits = 1
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

    /// Format P&L amount with +/- prefix
    private func formatPnL(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0"
    }

    /// Format P&L percentage
    private func formatPnLPercentage(_ pnl: Decimal, totalValue: Decimal) -> String {
        guard totalValue > 0 else { return "(0%)" }

        let costBasis = totalValue - pnl
        guard costBasis > 0 else { return "(0%)" }

        let percentage = (pnl / costBasis) * 100
        let doubleValue = NSDecimalNumber(decimal: percentage).doubleValue

        let sign = doubleValue >= 0 ? "+" : ""
        return "(\(sign)\(String(format: "%.1f", doubleValue))%)"
    }

    /// Per FR-009: Green for profit, red for loss
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

#Preview("Small Widget - With Data") {
    SmallWidgetView(entry: .snapshot())
        .containerBackground(.fill.tertiary, for: .widget)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("Small Widget - Empty") {
    SmallWidgetView(entry: .empty())
        .containerBackground(.fill.tertiary, for: .widget)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("Small Widget - Negative P&L") {
    SmallWidgetView(entry: PortfolioEntry(date: Date(), data: .negative))
        .containerBackground(.fill.tertiary, for: .widget)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
}

#Preview("Small Widget - Stale Data") {
    SmallWidgetView(entry: PortfolioEntry(date: Date(), data: .stale))
        .containerBackground(.fill.tertiary, for: .widget)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
}
