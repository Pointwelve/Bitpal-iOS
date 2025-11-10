//
//  SearchResultRow.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI

/// Row view for displaying a coin in search results
struct SearchResultRow: View {
    // MARK: - Properties

    let coin: CoinListItem

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.tiny) {
                Text(coin.name)
                    .font(Typography.headline)
                    .foregroundColor(.textPrimary)

                Text(coin.symbol.uppercased())
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .foregroundColor(.accent)
                .font(.system(size: 24))
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .cornerRadius(Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Add \(coin.name) to watchlist")
        .accessibilityHint("Tap to add this cryptocurrency")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.standard) {
        SearchResultRow(coin: CoinListItem(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin"
        ))

        SearchResultRow(coin: CoinListItem(
            id: "ethereum",
            symbol: "eth",
            name: "Ethereum"
        ))

        SearchResultRow(coin: CoinListItem(
            id: "cardano",
            symbol: "ada",
            name: "Cardano"
        ))
    }
    .padding(Spacing.medium)
}
