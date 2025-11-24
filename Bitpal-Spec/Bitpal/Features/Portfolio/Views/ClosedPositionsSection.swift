//
//  ClosedPositionsSection.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-23.
//  Closed Positions feature (003-closed-positions) - T022, T023
//

import SwiftUI

/// Collapsible section displaying closed trading positions
/// Per Constitution Principle II: Uses spring animations and Liquid Glass design
/// Per FR-004: Collapsed when > 5 positions, tap to expand/collapse
struct ClosedPositionsSection: View {
    let closedPositions: [ClosedPosition]

    /// FR-015: Expanded/collapsed state persists during current session only
    /// State resets to collapsed (false) on app restart
    @State private var isExpanded = false

    /// Check if section should collapse (> 5 positions)
    /// Per FR-004: Collapse threshold
    var shouldCollapse: Bool {
        closedPositions.count > 5
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
                    Text("(\(closedPositions.count))")
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

    /// List of closed positions
    /// Per Constitution Principle I: Uses LazyVStack for performance
    /// T043-T045: Tap to view transaction history (FR-009, FR-017)
    private var positionsList: some View {
        LazyVStack(spacing: Spacing.small) {
            ForEach(closedPositions) { position in
                NavigationLink(destination: TransactionHistoryView(
                    coinId: position.coinId,
                    coinName: position.coin.name,
                    transactions: position.cycleTransactions  // FR-017: Cycle-isolated transactions
                )) {
                    ClosedPositionRowView(closedPosition: position)
                }
                .buttonStyle(.plain)  // Preserve card styling
            }
        }
    }
}

#Preview("Few Positions") {
    let coin = Coin(
        id: "bitcoin",
        symbol: "btc",
        name: "Bitcoin",
        currentPrice: 50000,
        priceChange24h: 2.5,
        lastUpdated: Date(),
        marketCap: nil
    )

    let positions = (1...3).map { index in
        ClosedPosition(
            id: UUID(),
            coinId: "bitcoin",
            coin: coin,
            totalQuantity: Decimal(string: "1.0")!,
            avgCostPrice: 40000 + Decimal(index * 1000),
            avgSalePrice: 50000 + Decimal(index * 1000),
            closedDate: Date().addingTimeInterval(-Double(index * 86400)),
            cycleTransactions: []
        )
    }

    return ScrollView {
        ClosedPositionsSection(closedPositions: positions)
            .padding()
    }
}

#Preview("Many Positions - Collapsed") {
    let coin = Coin(
        id: "bitcoin",
        symbol: "btc",
        name: "Bitcoin",
        currentPrice: 50000,
        priceChange24h: 2.5,
        lastUpdated: Date(),
        marketCap: nil
    )

    let positions = (1...10).map { index in
        ClosedPosition(
            id: UUID(),
            coinId: "bitcoin",
            coin: coin,
            totalQuantity: Decimal(string: "1.0")!,
            avgCostPrice: 40000 + Decimal(index * 1000),
            avgSalePrice: 50000 + Decimal(index * 1000),
            closedDate: Date().addingTimeInterval(-Double(index * 86400)),
            cycleTransactions: []
        )
    }

    return ScrollView {
        ClosedPositionsSection(closedPositions: positions)
            .padding()
    }
}
