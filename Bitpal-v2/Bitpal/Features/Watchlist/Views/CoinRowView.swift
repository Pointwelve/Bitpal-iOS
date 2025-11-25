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
                    Text(Formatters.formatPrice(coin.currentPrice))
                        .font(Typography.priceDisplay)
                        .foregroundColor(.textPrimary)

                    PriceChangeLabel(priceChange: coin.priceChange24h)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(coin.name), \(Formatters.formatPrice(coin.currentPrice)), \(Formatters.formatPercentage(coin.priceChange24h)) change")
        .accessibilityHint("Swipe left to delete")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.standard) {
        // Large price (>= $1): 2 decimals
        CoinRowView(coin: Coin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            currentPrice: 45000.50,
            priceChange24h: 2.5,
            lastUpdated: Date()
        ))

        // Medium price (>= $1): 2 decimals
        CoinRowView(coin: Coin(
            id: "ethereum",
            symbol: "eth",
            name: "Ethereum",
            currentPrice: 2800.25,
            priceChange24h: -3.2,
            lastUpdated: Date()
        ))

        // Small price (>= $0.01): 4 decimals
        CoinRowView(coin: Coin(
            id: "dogecoin",
            symbol: "doge",
            name: "Dogecoin",
            currentPrice: 0.1488,
            priceChange24h: 5.2,
            lastUpdated: Date()
        ))

        // Very small price (>= $0.0001): 6 decimals
        CoinRowView(coin: Coin(
            id: "monad",
            symbol: "mon",
            name: "Monad",
            currentPrice: 0.03522,
            priceChange24h: 20.0,
            lastUpdated: Date()
        ))

        // Micro price (< $0.0001): 8 decimals
        CoinRowView(coin: Coin(
            id: "shiba-inu",
            symbol: "shib",
            name: "Shiba Inu",
            currentPrice: 0.00001234,
            priceChange24h: -1.5,
            lastUpdated: Date()
        ))
    }
    .padding(Spacing.medium)
}
