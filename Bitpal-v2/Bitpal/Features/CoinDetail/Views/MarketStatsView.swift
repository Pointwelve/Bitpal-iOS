//
//  MarketStatsView.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import SwiftUI

/// Market statistics view displaying market cap, volume, and circulating supply
/// Per Constitution Principle II: Uses LiquidGlassCard container
struct MarketStatsView: View {
    // MARK: - Properties

    let coinDetail: CoinDetail

    // MARK: - Body

    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Section header
                Text("Market Stats")
                    .font(Typography.headline)
                    .foregroundColor(.textPrimary)

                // Stats grid
                VStack(spacing: Spacing.standard) {
                    // Market Cap
                    if let marketCap = coinDetail.marketCap {
                        statRow(
                            title: "Market Cap",
                            value: Formatters.formatCompactCurrency(marketCap)
                        )
                    }

                    // 24h Volume
                    if let volume = coinDetail.totalVolume {
                        statRow(
                            title: "24h Volume",
                            value: Formatters.formatCompactCurrency(volume)
                        )
                    }

                    // Circulating Supply
                    if let supply = coinDetail.circulatingSupply {
                        statRow(
                            title: "Circulating Supply",
                            value: formatSupply(supply)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Typography.body)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(Typography.numericBody)
                .foregroundColor(.textPrimary)
        }
    }

    // MARK: - Helpers

    /// Format circulating supply with coin symbol
    private func formatSupply(_ supply: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        let formatted = formatter.string(from: supply as NSDecimalNumber) ?? "\(supply)"
        return "\(formatted) \(coinDetail.symbol.uppercased())"
    }
}

// MARK: - Preview

#Preview {
    MarketStatsView(coinDetail: CoinDetail(
        id: "bitcoin",
        symbol: "btc",
        name: "Bitcoin",
        image: nil,
        currentPrice: 45000.50,
        priceChange24h: 2.5,
        marketCap: 820_000_000_000,
        totalVolume: 25_000_000_000,
        circulatingSupply: 19_500_000
    ))
    .padding()
}
