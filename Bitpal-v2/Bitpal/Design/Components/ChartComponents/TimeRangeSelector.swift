//
//  TimeRangeSelector.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import SwiftUI

/// Horizontal time range selector buttons (Coinbase-style)
/// Shows time range options as pill buttons with selected state
struct TimeRangeSelector: View {
    // MARK: - Properties

    let ranges: [ChartTimeRange]
    @Binding var selectedRange: ChartTimeRange
    var chartType: ChartType = .line
    var onRangeSelected: ((ChartTimeRange) -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.small) {
            ForEach(ranges) { range in
                TimeRangeButton(
                    range: range,
                    isSelected: selectedRange == range,
                    displayName: chartType == .candle ? range.candleDisplayName : range.displayName,
                    action: {
                        guard range != selectedRange else { return }
                        // Only call callback - parent handles state via loadChartData
                        onRangeSelected?(range)
                    }
                )
            }
        }
        .padding(.vertical, Spacing.small)
    }
}

// MARK: - Time Range Button

struct TimeRangeButton: View {
    let range: ChartTimeRange
    let isSelected: Bool
    let displayName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(displayName)
                .font(Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.textSecondary.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(range.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.large) {
        // Line chart ranges (5 options)
        TimeRangeSelector(
            ranges: ChartTimeRange.lineRanges,
            selectedRange: .constant(.oneDay),
            chartType: .line
        )

        // Candle chart ranges (3 options: 30M, 4H, 4D)
        TimeRangeSelector(
            ranges: ChartTimeRange.candleRanges,
            selectedRange: .constant(.oneDay),
            chartType: .candle
        )
    }
    .padding()
}
