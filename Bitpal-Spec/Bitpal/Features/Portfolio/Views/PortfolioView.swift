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
        ScrollView {
            LazyVStack(spacing: Spacing.standard) {
                // Summary Card (T040)
                summaryCard

                // Last Updated Badge (T055)
                if let lastUpdate = viewModel.lastUpdateTime {
                    lastUpdatedBadge(lastUpdate)
                }

                // Holdings List
                ForEach(viewModel.holdings) { holding in
                    NavigationLink(destination: TransactionHistoryView(coinId: holding.id, coinName: holding.coin.name)) {
                        HoldingRowView(holding: holding)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
        }
    }

    // MARK: - Summary Card (T040)

    /// Portfolio summary card showing total value and P&L
    /// Per FR-012: Display portfolio summary
    private var summaryCard: some View {
        LiquidGlassCard {
            VStack(spacing: Spacing.standard) {
                // Total Value
                VStack(spacing: Spacing.tiny) {
                    Text("Total Value")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                    Text(Formatters.formatCurrency(viewModel.totalValue))
                        .font(Typography.largeTitle)
                        .fontWeight(.bold)
                }

                Divider()

                // Total P&L
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text("Total P&L")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(formatProfitLoss(viewModel.totalProfitLoss))
                            .font(Typography.title3)
                            .foregroundColor(summaryProfitLossColor)
                    }

                    Spacer()

                    // P&L Percentage
                    Text(formatPercentage(viewModel.totalProfitLossPercentage))
                        .font(Typography.title3)
                        .foregroundColor(summaryProfitLossColor)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.totalProfitLossPercentage) // T042
                }
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

    // MARK: - Helpers

    private var summaryProfitLossColor: Color {
        if viewModel.totalProfitLoss > 0 {
            return .profitGreen
        } else if viewModel.totalProfitLoss < 0 {
            return .lossRed
        } else {
            return .textSecondary
        }
    }

    private func formatProfitLoss(_ value: Decimal) -> String {
        let prefix = value > 0 ? "+" : ""
        return prefix + Formatters.formatCurrency(value)
    }

    private func formatPercentage(_ value: Decimal) -> String {
        let prefix = value > 0 ? "+" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let formatted = formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
        return "(\(prefix)\(formatted)%)"
    }
}

#Preview {
    PortfolioView()
}
