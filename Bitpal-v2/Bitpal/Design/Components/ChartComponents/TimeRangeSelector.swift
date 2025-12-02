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
    var onRangeSelected: ((ChartTimeRange) -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.small) {
            ForEach(ranges) { range in
                TimeRangeButton(
                    range: range,
                    isSelected: selectedRange == range,
                    action: {
                        guard range != selectedRange else { return }
                        // Call callback first, before updating binding
                        onRangeSelected?(range)
                        selectedRange = range
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(range.displayName)
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
            selectedRange: .constant(.oneDay)
        )

        // Candle chart ranges (7 options)
        TimeRangeSelector(
            ranges: ChartTimeRange.candleRanges,
            selectedRange: .constant(.fourHours)
        )
    }
    .padding()
}
