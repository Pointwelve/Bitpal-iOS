//
//  ChartStatsBar.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import SwiftUI

/// Statistics bar displaying period high, low, and price change
/// Shows above or below the chart with color-coded price change
struct ChartStatsBar: View {
    // MARK: - Properties

    let statistics: ChartStatistics

    // MARK: - Computed Properties

    private var changeColor: Color {
        if statistics.priceChange > 0 {
            return .profitGreen
        } else if statistics.priceChange < 0 {
            return .lossRed
        } else {
            return .textSecondary
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Period High
            statItem(
                title: "High",
                value: Formatters.formatPrice(statistics.periodHigh),
                color: .textPrimary
            )

            Spacer()

            // Period Low
            statItem(
                title: "Low",
                value: Formatters.formatPrice(statistics.periodLow),
                color: .textPrimary
            )

            Spacer()

            // Price Change
            statItem(
                title: "Change",
                value: Formatters.formatPercentage(statistics.percentageChange),
                color: changeColor
            )
        }
        .padding(.vertical, Spacing.small)
    }

    // MARK: - Subviews

    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: Spacing.tiny) {
            Text(title)
                .font(Typography.caption)
                .foregroundColor(.textSecondary)

            Text(value)
                .font(Typography.numericCaption)
                .foregroundColor(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.large) {
        // Positive change
        ChartStatsBar(statistics: ChartStatistics(
            periodHigh: 46500,
            periodLow: 44000,
            startPrice: 44500,
            endPrice: 45500
        ))

        // Negative change
        ChartStatsBar(statistics: ChartStatistics(
            periodHigh: 46500,
            periodLow: 44000,
            startPrice: 45500,
            endPrice: 44500
        ))

        // Zero change
        ChartStatsBar(statistics: ChartStatistics(
            periodHigh: 46500,
            periodLow: 44000,
            startPrice: 45000,
            endPrice: 45000
        ))
    }
    .padding()
}
