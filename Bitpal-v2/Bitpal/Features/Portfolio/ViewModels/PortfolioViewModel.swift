//
//  PortfolioViewModel.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import Foundation
import SwiftData
import Observation
import OSLog
import WidgetKit

/// Main ViewModel for Portfolio feature
/// Per Constitution Principle III: Uses @Observable (NOT ObservableObject)
@Observable
final class PortfolioViewModel {
    // MARK: - State

    var holdings: [Holding] = []
    var closedPositions: [ClosedPosition] = [] // T017: Closed positions tracking
    var closedPositionGroups: [ClosedPositionGroup] = [] // FR-019: Grouped closed positions
    var partialRealizedGains: Decimal = 0 // Amendment 2025-12-05: Partial sale realized P&L
    var isLoading = false
    var errorMessage: String?
    var lastUpdateTime: Date?

    // MARK: - Dependencies

    private var _coinGeckoService: CoinGeckoService?
    private var _priceUpdateService: PriceUpdateService?
    private var modelContext: ModelContext?
    private var updateTask: Task<Void, Never>?

    @MainActor
    private var coinGeckoService: CoinGeckoService {
        if let service = _coinGeckoService { return service }
        let service = CoinGeckoService.shared
        _coinGeckoService = service
        return service
    }

    @MainActor
    private var priceUpdateService: PriceUpdateService {
        if let service = _priceUpdateService { return service }
        let service = PriceUpdateService.shared
        _priceUpdateService = service
        return service
    }

    // MARK: - Initialization

    init() {
        // Services are lazily initialized when needed
    }

    deinit {
        updateTask?.cancel()
        updateTask = nil
    }

    // MARK: - Computed Properties (T038)

    /// Total portfolio value (sum of all holdings)
    /// Per FR-012: Display portfolio summary
    var totalValue: Decimal {
        holdings.reduce(0) { $0 + $1.currentValue }
    }

    /// Total profit/loss across all holdings
    var totalProfitLoss: Decimal {
        holdings.reduce(0) { $0 + $1.profitLoss }
    }

    /// Total profit/loss percentage
    /// Per FR-026: Display to 2 decimal places
    var totalProfitLossPercentage: Decimal {
        let totalCost = holdings.reduce(0) { $0 + $1.totalCost }
        guard totalCost > 0 else { return 0 }
        return ((totalValue / totalCost) - 1) * 100
    }

    /// T031: Portfolio summary with unrealized and realized P&L
    /// Per US2: Comprehensive financial picture
    /// Per Amendment 2025-12-05: Includes partial sale realized gains
    var portfolioSummary: PortfolioSummary {
        computePortfolioSummary(
            holdings: holdings,
            closedPositions: closedPositions,
            partialRealizedGains: partialRealizedGains
        )
    }

    /// Check if portfolio is empty (T039, T070: Fixed to account for closed positions)
    /// Per FR-027: Show empty state with "Add Your First Transaction" button
    /// T070: Must check both holdings AND closedPositions to prevent empty state when user has only closed positions
    var isEmpty: Bool {
        holdings.isEmpty && closedPositions.isEmpty
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Actions (T029)

    /// Load portfolio with current prices
    /// Per SC-003: Must complete in <500ms with cached prices
    @MainActor
    func loadPortfolioWithPrices() async {
        guard let context = modelContext else {
            Logger.error.error("Model context not configured")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Fetch all transactions from Swift Data
            let descriptor = FetchDescriptor<Transaction>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let transactions = try context.fetch(descriptor)

            guard !transactions.isEmpty else {
                holdings = []
                closedPositions = []
                closedPositionGroups = []
                partialRealizedGains = 0
                isLoading = false
                return
            }

            // Get unique coin IDs from transactions
            let coinIds = Array(Set(transactions.map { $0.coinId }))

            // Fetch current prices from CoinGecko
            let prices = try await coinGeckoService.fetchMarketData(coinIds: coinIds)

            // Compute holdings
            holdings = computeHoldings(transactions: transactions, currentPrices: prices)

            // FR-018: Sort holdings by current value (highest first)
            holdings.sort { $0.currentValue > $1.currentValue }

            // T018, T019: Compute closed positions
            closedPositions = computeClosedPositions(transactions: transactions, currentPrices: prices)

            // FR-019, FR-022: Compute closed position groups
            closedPositionGroups = computeClosedPositionGroups(closedPositions: closedPositions)

            // Amendment 2025-12-05: Compute partial realized gains from open positions
            partialRealizedGains = computePartialRealizedGains(transactions: transactions, currentPrices: prices)

            lastUpdateTime = Date()

            // T015: Update widget data and refresh timelines after portfolio load
            WidgetDataProvider.shared.updateAndReloadWidgets(
                summary: portfolioSummary,
                holdings: holdings
            )

            Logger.logic.info("Loaded portfolio: \(self.holdings.count) holdings, \(self.closedPositions.count) closed positions from \(transactions.count) transactions")

        } catch {
            Logger.error.error("Failed to load portfolio: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Periodic Updates (T030)

    /// Start periodic price updates
    /// Per Constitution Principle I: Throttled to 30-second intervals
    func startPeriodicUpdates() {
        stopPeriodicUpdates()

        updateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await self?.loadPortfolioWithPrices()
            }
        }

        Logger.ui.info("Started periodic portfolio updates")
    }

    /// Stop periodic price updates
    func stopPeriodicUpdates() {
        updateTask?.cancel()
        updateTask = nil
        Logger.ui.info("Stopped periodic portfolio updates")
    }

    // MARK: - Import/Export (T011)

    /// Export all transactions to a shareable file URL
    /// - Returns: URL to temporary JSON file for sharing
    /// - Throws: ImportError or encoding errors
    @MainActor
    func exportPortfolio() async throws -> URL {
        guard let context = modelContext else {
            throw ImportError.fileAccessDenied
        }

        // Fetch all transactions
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let transactions = try context.fetch(descriptor)

        guard !transactions.isEmpty else {
            throw ImportError.emptyFile
        }

        // Export to JSON
        let service = ImportExportService.shared
        let jsonData = try service.exportTransactions(transactions)
        let url = try service.createExportURL(data: jsonData)

        Logger.persistence.info("Exported \(transactions.count) transactions to \(url.lastPathComponent)")
        return url
    }

    /// Check if there are transactions to export
    @MainActor
    var hasTransactionsToExport: Bool {
        guard let context = modelContext else { return false }
        let descriptor = FetchDescriptor<Transaction>()
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    // MARK: - Transaction Management (T050, T051)

    /// Delete a transaction and recalculate holdings
    @MainActor
    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let context = modelContext else {
            throw PortfolioError.deleteFailed(NSError(domain: "Bitpal", code: -1))
        }

        context.delete(transaction)

        do {
            try context.save()
            await loadPortfolioWithPrices()

            // T016: Reload widget timelines after transaction changes
            WidgetDataProvider.shared.reloadWidgetTimelines()

            Logger.persistence.info("Deleted transaction: \(transaction.id)")
        } catch {
            Logger.persistence.error("Failed to delete transaction: \(error)")
            throw PortfolioError.deleteFailed(error)
        }
    }

    /// Get holding quantity for a specific coin
    func getHoldingQuantity(for coinId: String) -> Decimal {
        holdings.first { $0.id == coinId }?.totalAmount ?? 0
    }
}
