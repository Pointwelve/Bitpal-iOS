//
//  ChartTypeToggle.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/7/25.
//

import SwiftUI

/// Segmented control for toggling between line and candlestick chart types
/// Per Constitution Principle II: 44pt minimum tap targets
struct ChartTypeToggle: View {
    // MARK: - Properties

    @Binding var selectedType: ChartType
    var onTypeChanged: ((ChartType) -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.tiny) {
            ForEach(ChartType.allCases) { chartType in
                ChartTypeButton(
                    type: chartType,
                    isSelected: selectedType == chartType,
                    action: {
                        guard chartType != selectedType else { return }
                        // Only call the callback - let parent handle the state change
                        // This ensures data loading happens before the type switches
                        onTypeChanged?(chartType)
                    }
                )
            }
        }
        .padding(Spacing.tiny)
        .background(Color.backgroundSecondary.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - Chart Type Button

private struct ChartTypeButton: View {
    let type: ChartType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: type.iconName)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                .frame(width: 44, height: 32)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.backgroundPrimary : Color.clear)
                        .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.large) {
        ChartTypeToggle(selectedType: .constant(.line))
        ChartTypeToggle(selectedType: .constant(.candle))
    }
    .padding()
    .background(Color.backgroundPrimary)
}
