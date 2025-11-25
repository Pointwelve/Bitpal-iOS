//
//  PortfolioView.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import SwiftUI
import SwiftData

/// Main portfolio view with summary and holdings list
/// Per Constitution Principle II: Follows Liquid Glass design system
struct PortfolioView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PortfolioViewModel()
    @State private var showAddTransaction = false
    @State private var showError = false
    @State private var scrollProxy: ScrollViewProxy? // T038: For scroll-to-section

    // FR-017: Query all transactions for cycle filtering
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Portfolio")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showAddTransaction = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .task {
                    viewModel.configure(modelContext: modelContext)
                    await viewModel.loadPortfolioWithPrices()
                    viewModel.startPeriodicUpdates()
                }
                .onDisappear {
                    viewModel.stopPeriodicUpdates()
                }
                .refreshable {
                    await viewModel.loadPortfolioWithPrices()
                }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(existingHoldings: viewModel.holdings) {
                Task {
                    await viewModel.loadPortfolioWithPrices()
                }
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showError = newValue != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                viewModel.errorMessage = nil
                showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.holdings.isEmpty {
            LoadingView()
        } else if viewModel.isEmpty {
            emptyStateView
        } else {
            portfolioContent
        }
    }

    // MARK: - Portfolio Content

    private var portfolioContent: some View {
        // T038: ScrollViewReader for scroll-to-section functionality
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.standard) {
                    // T037: New Portfolio Summary View with 4 P&L metrics
                    PortfolioSummaryView(summary: viewModel.portfolioSummary) {
                        // T038: Scroll to Closed Positions section on Realized P&L tap
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            proxy.scrollTo("closedPositionsSection", anchor: .top)
                        }
                    }

                    // Last Updated Badge (T055)
                    if let lastUpdate = viewModel.lastUpdateTime {
                        lastUpdatedBadge(lastUpdate)
                    }

                    // Holdings List
                    ForEach(viewModel.holdings) { holding in
                        NavigationLink(destination: TransactionHistoryView(
                            coinId: holding.id,
                            coinName: holding.coin.name,
                            transactions: getOpenCycleTransactions(for: holding.id)  // FR-017: Cycle-isolated transactions
                        )) {
                            HoldingRowView(holding: holding)
                        }
                        .buttonStyle(.plain)
                    }

                    // T024, T038: Closed Positions Section (displayed below holdings)
                    // Per FR-002: Only show when closed positions exist
                    // FR-019: Display grouped closed positions
                    if !viewModel.closedPositionGroups.isEmpty {
                        ClosedPositionsSection(closedPositionGroups: viewModel.closedPositionGroups)
                            .padding(.top, Spacing.medium)
                            .id("closedPositionsSection") // T038: ID for scrolling
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    // MARK: - Empty State (T041)

    /// Empty state with "Add Your First Transaction" button
    /// Per FR-027: Prominent empty state action
    private var emptyStateView: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: "chart.pie")
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)

            Text("No Holdings Yet")
                .font(Typography.title2)

            Text("Start tracking by adding your first transaction.")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.large)

            Button("Add Your First Transaction") {
                showAddTransaction = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, Spacing.medium)
        }
        .padding()
    }

    // MARK: - Last Updated Badge

    private func lastUpdatedBadge(_ date: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack {
                Spacer()
                Text("Updated \(relativeTimeString(from: date, to: context.date))")
                    .font(Typography.caption)
                    .foregroundColor(.textTertiary)
                Spacer()
            }
        }
        .padding(.vertical, Spacing.tiny)
    }

    private func relativeTimeString(from date: Date, to now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }

    // MARK: - FR-017: Open Cycle Transaction Filtering

    /// Get open cycle transactions for a specific coin
    /// FR-017: Transaction history must show only current cycle transactions
    /// - Parameter coinId: The coin to get transactions for
    /// - Returns: Transactions from the current open cycle only (after last close)
    private func getOpenCycleTransactions(for coinId: String) -> [Transaction] {
        // Filter transactions for this coin
        let coinTransactions = allTransactions.filter { $0.coinId == coinId }

        // Sort by date (chronological order)
        let sortedTxs = coinTransactions.sorted { $0.date < $1.date }

        // Track running balance and find last cycle closure index
        var runningBalance: Decimal = 0
        var lastClosureIndex: Int? = nil

        for (index, tx) in sortedTxs.enumerated() {
            // Update running balance
            switch tx.type {
            case .buy:
                runningBalance += tx.amount
            case .sell:
                runningBalance -= tx.amount
            }

            // Check if cycle closed (balance within tolerance of zero)
            if abs(runningBalance) < 0.00000001 {
                lastClosureIndex = index
                runningBalance = 0
            }
        }

        // If no cycle closures found, all transactions are from open cycle
        guard let closureIndex = lastClosureIndex else {
            return sortedTxs
        }

        // Return only transactions after the last closure
        let openCycleStart = closureIndex + 1
        guard openCycleStart < sortedTxs.count else {
            return []  // No open cycle transactions exist
        }

        return Array(sortedTxs[openCycleStart...])
    }

}

#Preview {
    PortfolioView()
}
