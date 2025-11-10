//
//  CoinRowView.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI

/// Row view for displaying a coin in the watchlist
/// Per Constitution Principle II: Liquid Glass design with LiquidGlassCard
/// Per Constitution Principle I: Equatable for efficient SwiftUI diffing
struct CoinRowView: View, Equatable {
    // MARK: - Properties

    let coin: Coin

    // MARK: - Equatable Conformance

    static func == (lhs: CoinRowView, rhs: CoinRowView) -> Bool {
        lhs.coin == rhs.coin
    }

    // MARK: - Body

    var body: some View {
        LiquidGlassCard {
            HStack(alignment: .center, spacing: Spacing.medium) {
                // Coin info
                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    Text(coin.name)
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    Text(coin.symbol.uppercased())
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Price info
                VStack(alignment: .trailing, spacing: Spacing.tiny) {
                    Text(Formatters.formatCurrency(coin.currentPrice))
                        .font(Typography.priceDisplay)
                        .foregroundColor(.textPrimary)

                    PriceChangeLabel(priceChange: coin.priceChange24h)
                }
            }
            .padding(Spacing.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(coin.name), \(Formatters.formatCurrency(coin.currentPrice)), \(Formatters.formatPercentage(coin.priceChange24h)) change")
        .accessibilityHint("Swipe left to delete")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.standard) {
        CoinRowView(coin: Coin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            currentPrice: 45000.50,
            priceChange24h: 2.5,
            lastUpdated: Date()
        ))

        CoinRowView(coin: Coin(
            id: "ethereum",
            symbol: "eth",
            name: "Ethereum",
            currentPrice: 2800.25,
            priceChange24h: -3.2,
            lastUpdated: Date()
        ))

        CoinRowView(coin: Coin(
            id: "cardano",
            symbol: "ada",
            name: "Cardano",
            currentPrice: 0.45,
            priceChange24h: 0.0,
            lastUpdated: Date()
        ))
    }
    .padding(Spacing.medium)
}
