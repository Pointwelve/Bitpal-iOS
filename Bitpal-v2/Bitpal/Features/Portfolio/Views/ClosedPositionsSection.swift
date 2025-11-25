//
//  ClosedPositionsSection.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-23.
//  Closed Positions feature (003-closed-positions) - T022, T023
//  Updated 2025-11-24 for grouping feature - FR-019, FR-020, FR-021
//

import SwiftUI

/// Collapsible section displaying closed trading positions grouped by coin
/// Per Constitution Principle II: Uses spring animations and Liquid Glass design
/// Per FR-019: Groups closed positions by coin
/// Per FR-022: Sorts groups by most recent close date
struct ClosedPositionsSection: View {
    let closedPositionGroups: [ClosedPositionGroup]

    /// FR-015: Expanded/collapsed state persists during current session only
    /// State resets to collapsed (false) on app restart
    @State private var isExpanded = false

    /// Check if section should collapse (> 5 groups)
    /// Per FR-004: Collapse threshold (now applies to groups, not individual positions)
    var shouldCollapse: Bool {
        closedPositionGroups.count > 5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Section header (tappable if should collapse)
            sectionHeader

            // Positions list (show if expanded or <= 5 items)
            if !shouldCollapse || isExpanded {
                positionsList
            }
        }
    }

    // MARK: - Components

    /// Section header with title, count badge, and chevron
    private var sectionHeader: some View {
        Button {
            if shouldCollapse {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
        } label: {
            HStack {
                Text("Closed Positions")
                    .font(Typography.title2)
                    .foregroundColor(.textPrimary)

                if shouldCollapse {
                    Text("(\(closedPositionGroups.count))")
                        .font(Typography.title3)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                if shouldCollapse {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.textSecondary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.plain)
        .disabled(!shouldCollapse) // Only tappable if collapsible
    }

    /// List of closed position groups
    /// Per Constitution Principle I: Uses LazyVStack for performance
    /// Per FR-021: Tap group to navigate to coin-specific cycle list
    private var positionsList: some View {
        LazyVStack(spacing: Spacing.small) {
            ForEach(closedPositionGroups) { group in
                NavigationLink(destination: CoinClosedPositionsView(
                    coinId: group.coinId,
                    coinName: group.coin.name,
                    closedPositions: group.closedPositions
                )) {
                    ClosedPositionGroupRowView(group: group)
                }
                .buttonStyle(.plain)  // Preserve card styling
            }
        }
    }
}

// MARK: - Closed Position Group Row View

/// Row view for displaying aggregated closed position group
/// Per FR-020: Shows cycle count and total realized P&L
struct ClosedPositionGroupRowView: View, Equatable {
    let group: ClosedPositionGroup

    static func == (lhs: ClosedPositionGroupRowView, rhs: ClosedPositionGroupRowView) -> Bool {
        lhs.group == rhs.group
    }

    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Header: Coin name, symbol, and cycle count
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text(group.coin.name)
                            .font(Typography.headline)
                        Text(group.coin.symbol.uppercased())
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Text("\(group.cycleCount) cycle\(group.cycleCount == 1 ? "" : "s")")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()

                // Aggregated metrics
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text("Total Realized P&L")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(formatProfitLoss(group.totalRealizedPnL))
                            .font(Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(profitLossColor)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: Spacing.tiny) {
                        Text("Return")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(formatPercentage(group.totalRealizedPnLPercentage))
                            .font(Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(profitLossColor)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Color for P&L display
    private var profitLossColor: Color {
        if group.totalRealizedPnL > 0 {
            return .profitGreen
        } else if group.totalRealizedPnL < 0 {
            return .lossRed
        } else {
            return .textSecondary
        }
    }

    /// Format P&L with sign
    private func formatProfitLoss(_ value: Decimal) -> String {
        let prefix = value > 0 ? "+" : ""
        return prefix + Formatters.formatCurrency(value)
    }

    /// Format percentage with 2 decimal places
    private func formatPercentage(_ value: Decimal) -> String {
        let prefix = value > 0 ? "+" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let formatted = formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
        return "\(prefix)\(formatted)%"
    }
}

#Preview("Few Groups") {
    let coin1 = Coin(
        id: "bitcoin",
        symbol: "btc",
        name: "Bitcoin",
        currentPrice: 50000,
        priceChange24h: 2.5,
        lastUpdated: Date(),
        marketCap: nil
    )

    let coin2 = Coin(
        id: "ethereum",
        symbol: "eth",
        name: "Ethereum",
        currentPrice: 3000,
        priceChange24h: 1.5,
        lastUpdated: Date(),
        marketCap: nil
    )

    let positions1 = (1...2).map { index in
        ClosedPosition(
            id: UUID(),
            coinId: "bitcoin",
            coin: coin1,
            totalQuantity: Decimal(string: "1.0")!,
            avgCostPrice: 40000,
            avgSalePrice: 50000,
            closedDate: Date().addingTimeInterval(-Double(index * 86400)),
            cycleTransactions: []
        )
    }

    let positions2 = [
        ClosedPosition(
            id: UUID(),
            coinId: "ethereum",
            coin: coin2,
            totalQuantity: Decimal(string: "10.0")!,
            avgCostPrice: 2000,
            avgSalePrice: 3000,
            closedDate: Date().addingTimeInterval(-172800),
            cycleTransactions: []
        )
    ]

    let groups = computeClosedPositionGroups(closedPositions: positions1 + positions2)

    return ScrollView {
        ClosedPositionsSection(closedPositionGroups: groups)
            .padding()
    }
}

#Preview("Many Groups - Collapsed") {
    let coins = [
        Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", currentPrice: 50000, priceChange24h: 2.5, lastUpdated: Date(), marketCap: nil),
        Coin(id: "ethereum", symbol: "eth", name: "Ethereum", currentPrice: 3000, priceChange24h: 1.5, lastUpdated: Date(), marketCap: nil),
        Coin(id: "cardano", symbol: "ada", name: "Cardano", currentPrice: 0.5, priceChange24h: -0.5, lastUpdated: Date(), marketCap: nil),
        Coin(id: "solana", symbol: "sol", name: "Solana", currentPrice: 100, priceChange24h: 3.0, lastUpdated: Date(), marketCap: nil),
        Coin(id: "polkadot", symbol: "dot", name: "Polkadot", currentPrice: 7, priceChange24h: 0.8, lastUpdated: Date(), marketCap: nil),
        Coin(id: "chainlink", symbol: "link", name: "Chainlink", currentPrice: 15, priceChange24h: 1.2, lastUpdated: Date(), marketCap: nil),
        Coin(id: "avalanche", symbol: "avax", name: "Avalanche", currentPrice: 35, priceChange24h: 2.1, lastUpdated: Date(), marketCap: nil)
    ]

    var allPositions: [ClosedPosition] = []
    for (index, coin) in coins.enumerated() {
        let position = ClosedPosition(
            id: UUID(),
            coinId: coin.id,
            coin: coin,
            totalQuantity: Decimal(string: "1.0")!,
            avgCostPrice: coin.currentPrice * 0.8,
            avgSalePrice: coin.currentPrice,
            closedDate: Date().addingTimeInterval(-Double(index * 86400)),
            cycleTransactions: []
        )
        allPositions.append(position)
    }

    let groups = computeClosedPositionGroups(closedPositions: allPositions)

    return ScrollView {
        ClosedPositionsSection(closedPositionGroups: groups)
            .padding()
    }
}
