//
//  CoinHeaderView.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import SwiftUI

/// Header view displaying coin logo, name, symbol, price, and 24h change
/// Per Constitution Principle II: Uses Liquid Glass design with translucent materials
struct CoinHeaderView: View {
    // MARK: - Properties

    let coinDetail: CoinDetail

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            // Coin logo
            AsyncImage(url: coinDetail.image) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    coinPlaceholder
                case .empty:
                    ProgressView()
                @unknown default:
                    coinPlaceholder
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            // Coin name and symbol
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                Text(coinDetail.name)
                    .font(Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)

                Text(coinDetail.symbol.uppercased())
                    .font(Typography.subheadline)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Price and 24h change
            VStack(alignment: .trailing, spacing: Spacing.tiny) {
                Text(Formatters.formatPrice(coinDetail.currentPrice))
                    .font(Typography.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .monospacedDigit()

                PriceChangeLabel(priceChange: coinDetail.priceChange24h)
            }
        }
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(coinDetail.name), \(Formatters.formatPrice(coinDetail.currentPrice)), \(Formatters.formatPercentage(coinDetail.priceChange24h)) in 24 hours")
    }

    // MARK: - Subviews

    private var coinPlaceholder: some View {
        Circle()
            .fill(Color.backgroundSecondary)
            .overlay {
                Text(coinDetail.symbol.prefix(1).uppercased())
                    .font(Typography.headline)
                    .foregroundColor(.textSecondary)
            }
    }
}

// MARK: - Preview

#Preview {
    CoinHeaderView(coinDetail: CoinDetail(
        id: "bitcoin",
        symbol: "btc",
        name: "Bitcoin",
        image: URL(string: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"),
        currentPrice: 45000.50,
        priceChange24h: 2.5,
        marketCap: 820_000_000_000,
        totalVolume: 25_000_000_000,
        circulatingSupply: 19_500_000
    ))
    .padding()
}
