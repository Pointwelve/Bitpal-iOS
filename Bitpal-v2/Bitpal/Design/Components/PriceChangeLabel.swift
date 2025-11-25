//
//  PriceChangeLabel.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI

/// Color-coded price change percentage label
/// Per Constitution Principle II: Green for positive, red for negative
struct PriceChangeLabel: View {
    // MARK: - Properties

    let priceChange: Decimal

    // MARK: - Computed Properties

    private var formattedChange: String {
        Formatters.formatPercentage(priceChange)
    }

    private var changeColor: Color {
        if priceChange > 0 {
            return .profitGreen
        } else if priceChange < 0 {
            return .lossRed
        } else {
            return .textSecondary
        }
    }

    // MARK: - Body

    var body: some View {
        Text(formattedChange)
            .font(Typography.numericBody)
            .foregroundColor(changeColor)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.medium) {
        PriceChangeLabel(priceChange: 2.5)
            .padding()

        PriceChangeLabel(priceChange: -3.2)
            .padding()

        PriceChangeLabel(priceChange: 0)
            .padding()
    }
}
