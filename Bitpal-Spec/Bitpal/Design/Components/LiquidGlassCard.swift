//
//  LiquidGlassCard.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI

/// Reusable Liquid Glass design card component
/// Per Constitution Principle II: Liquid Glass design with translucent materials
struct LiquidGlassCard<Content: View>: View {
    // MARK: - Properties

    let content: Content

    // MARK: - Initialization

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(Spacing.cornerRadius)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.standard) {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Bitcoin")
                    .font(Typography.headline)
                Text("$45,000.50")
                    .font(Typography.priceDisplay)
                    .foregroundColor(Color.profitGreen)
            }
            .padding(Spacing.medium)
        }

        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Ethereum")
                    .font(Typography.headline)
                Text("$2,800.25")
                    .font(Typography.priceDisplay)
                    .foregroundColor(Color.lossRed)
            }
            .padding(Spacing.medium)
        }
    }
    .padding(Spacing.medium)
}
