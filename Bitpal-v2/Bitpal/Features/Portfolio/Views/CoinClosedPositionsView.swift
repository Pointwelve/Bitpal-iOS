//
//  CoinClosedPositionsView.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-24.
//  Closed Positions Grouping feature - FR-021
//

import SwiftUI

/// List view showing all closed trading cycles for a specific cryptocurrency.
/// Accessed by tapping a grouped closed position in Portfolio view.
/// Per FR-021: Navigate from grouped position to see all cycles for that coin
/// Per Constitution Principle II: Follows Liquid Glass design system
struct CoinClosedPositionsView: View {
    let coinId: String
    let coinName: String
    let closedPositions: [ClosedPosition]

    /// Initialize with coin details and its closed cycles
    /// - Parameters:
    ///   - coinId: CoinGecko coin ID
    ///   - coinName: Display name for navigation title
    ///   - closedPositions: All closed cycles for this coin (sorted by date descending)
    init(coinId: String, coinName: String, closedPositions: [ClosedPosition]) {
        self.coinId = coinId
        self.coinName = coinName
        // Sort by close date descending (most recent first)
        self.closedPositions = closedPositions.sorted { $0.closedDate > $1.closedDate }
    }

    var body: some View {
        Group {
            if closedPositions.isEmpty {
                emptyStateView
            } else {
                cycleList
            }
        }
        .navigationTitle(coinName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cycle List

    private var cycleList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.standard) {
                // Summary header
                summaryHeader

                // Cycle list
                ForEach(closedPositions) { position in
                    NavigationLink(destination: TransactionHistoryView(
                        coinId: position.coinId,
                        coinName: position.coin.name,
                        transactions: position.cycleTransactions
                    )) {
                        ClosedPositionRowView(closedPosition: position)
                    }
                    .buttonStyle(.plain)  // Preserve card styling
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
        }
    }

    // MARK: - Summary Header

    /// Summary card showing aggregated metrics for all cycles
    private var summaryHeader: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Header
                HStack {
                    Text("Summary")
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(closedPositions.count) cycle\(closedPositions.count == 1 ? "" : "s")")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()

                // Metrics
                VStack(spacing: Spacing.small) {
                    // Total Realized P&L
                    HStack {
                        Text("Total Realized P&L")
                            .font(Typography.body)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatProfitLoss(totalRealizedPnL))
                                .font(Typography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(totalPnLColor)
                            Text(formatPercentage(totalRealizedPnLPercentage))
                                .font(Typography.caption)
                                .foregroundColor(totalPnLColor)
                        }
                    }

                    // Average P&L per cycle
                    HStack {
                        Text("Average P&L per cycle")
                            .font(Typography.body)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(formatProfitLoss(averagePnLPerCycle))
                            .font(Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(totalPnLColor)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)

            Text("No Closed Positions")
                .font(Typography.title2)

            Text("Closed trading cycles for \(coinName) will appear here.")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xlarge)
        }
        .padding()
    }

    // MARK: - Computed Properties

    /// Total realized P&L across all cycles
    private var totalRealizedPnL: Decimal {
        closedPositions.reduce(0) { $0 + $1.realizedPnL }
    }

    /// Weighted average percentage across all cycles
    private var totalRealizedPnLPercentage: Decimal {
        let totalInvested = closedPositions.reduce(0) { $0 + ($1.avgCostPrice * $1.totalQuantity) }
        let totalRevenue = closedPositions.reduce(0) { $0 + ($1.avgSalePrice * $1.totalQuantity) }

        guard totalInvested > 0 else { return 0 }
        return ((totalRevenue / totalInvested) - 1) * 100
    }

    /// Average P&L per cycle
    private var averagePnLPerCycle: Decimal {
        guard !closedPositions.isEmpty else { return 0 }
        return totalRealizedPnL / Decimal(closedPositions.count)
    }

    /// Color for total P&L display
    private var totalPnLColor: Color {
        if totalRealizedPnL > 0 {
            return .profitGreen
        } else if totalRealizedPnL < 0 {
            return .lossRed
        } else {
            return .textSecondary
        }
    }

    // MARK: - Helpers

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

#Preview {
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

    return NavigationStack {
        CoinClosedPositionsView(
            coinId: "bitcoin",
            coinName: "Bitcoin",
            closedPositions: positions
        )
    }
}
