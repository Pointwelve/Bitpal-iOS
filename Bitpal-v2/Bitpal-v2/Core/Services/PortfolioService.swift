//
//  PortfolioService.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftData
import Foundation
import Observation

@MainActor
@Observable
final class PortfolioService {
    static let shared = PortfolioService()
    
    private(set) var portfolios: [Portfolio] = []
    private(set) var currentPortfolio: Portfolio?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private var modelContext: ModelContext?
    private let priceStreamService = PriceStreamService.shared
    
    private init() {
        Task {
            await startPriceUpdates()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        modelContext = context
        Task {
            await loadPortfolios()
        }
    }
    
    // MARK: - Portfolio Management
    
    func loadPortfolios() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<Portfolio>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            portfolios = try context.fetch(descriptor)
            
            if currentPortfolio == nil {
                currentPortfolio = portfolios.first { $0.isDefault } ?? portfolios.first
            }
            
            await updateAllPortfolioValues()
            
        } catch {
            errorMessage = "Failed to load portfolios: \(error.localizedDescription)"
        }
    }
    
    func createPortfolio(name: String, isDefault: Bool = false) async throws -> Portfolio {
        guard let context = modelContext else {
            throw PortfolioError.contextNotAvailable
        }
        
        if isDefault {
            for portfolio in portfolios {
                portfolio.isDefault = false
            }
        }
        
        let portfolio = Portfolio(name: name, isDefault: isDefault)
        context.insert(portfolio)
        
        try context.save()
        await loadPortfolios()
        
        return portfolio
    }
    
    func deletePortfolio(_ portfolio: Portfolio) async throws {
        guard let context = modelContext else {
            throw PortfolioError.contextNotAvailable
        }
        
        if portfolio.isDefault && portfolios.count > 1 {
            if let firstOther = portfolios.first(where: { $0.id != portfolio.id }) {
                firstOther.isDefault = true
            }
        }
        
        context.delete(portfolio)
        try context.save()
        await loadPortfolios()
    }
    
    func setDefaultPortfolio(_ portfolio: Portfolio) async throws {
        guard let context = modelContext else {
            throw PortfolioError.contextNotAvailable
        }
        
        for p in portfolios {
            p.isDefault = (p.id == portfolio.id)
        }
        
        currentPortfolio = portfolio
        try context.save()
    }
    
    // MARK: - Holdings Management
    
    func addHolding(
        to portfolio: Portfolio,
        currency: Currency,
        quantity: Double,
        averageCost: Double
    ) async throws -> Holding {
        guard let context = modelContext else {
            throw PortfolioError.contextNotAvailable
        }
        
        if let existingHolding = portfolio.holdings.first(where: { $0.currency?.id == currency.id }) {
            let newQuantity = existingHolding.quantity + quantity
            let newTotalCost = existingHolding.totalCost + (quantity * averageCost)
            existingHolding.averageCost = newTotalCost / newQuantity
            existingHolding.quantity = newQuantity
            existingHolding.totalCost = newTotalCost
            existingHolding.updateCalculations()
            
            try context.save()
            await updatePortfolioValue(portfolio)
            return existingHolding
        } else {
            let holding = Holding(currency: currency, quantity: quantity, averageCost: averageCost, portfolio: portfolio)
            portfolio.holdings.append(holding)
            context.insert(holding)
            
            try context.save()
            await updatePortfolioValue(portfolio)
            return holding
        }
    }
    
    func removeHolding(_ holding: Holding) async throws {
        guard let context = modelContext else {
            throw PortfolioError.contextNotAvailable
        }
        
        if let portfolio = holding.portfolio {
            portfolio.holdings.removeAll { $0.id == holding.id }
            await updatePortfolioValue(portfolio)
        }
        
        context.delete(holding)
        try context.save()
    }
    
    func updateHolding(
        _ holding: Holding,
        quantity: Double,
        averageCost: Double
    ) async throws {
        guard let context = modelContext else {
            throw PortfolioError.contextNotAvailable
        }
        
        holding.quantity = quantity
        holding.averageCost = averageCost
        holding.totalCost = quantity * averageCost
        holding.updateCalculations()
        
        if let portfolio = holding.portfolio {
            await updatePortfolioValue(portfolio)
        }
        
        try context.save()
    }
    
    // MARK: - Transaction Management
    
    func addTransaction(
        to portfolio: Portfolio,
        currency: Currency,
        type: TransactionType,
        quantity: Double,
        price: Double,
        fee: Double = 0.0,
        exchange: String = "",
        notes: String = ""
    ) async throws -> Transaction {
        guard let context = modelContext else {
            throw PortfolioError.contextNotAvailable
        }
        
        let transaction = Transaction(
            currency: currency,
            type: type,
            quantity: quantity,
            price: price,
            fee: fee,
            exchange: exchange,
            notes: notes,
            portfolio: portfolio
        )
        
        portfolio.transactions.append(transaction)
        context.insert(transaction)
        
        if let holding = portfolio.holdings.first(where: { $0.currency?.id == currency.id }) {
            holding.addTransaction(transaction)
        } else if type == .buy {
            let newHolding = Holding(currency: currency, quantity: quantity, averageCost: price, portfolio: portfolio)
            portfolio.holdings.append(newHolding)
            context.insert(newHolding)
        }
        
        try context.save()
        await updatePortfolioValue(portfolio)
        
        return transaction
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let context = modelContext else {
            throw PortfolioError.contextNotAvailable
        }
        
        if let portfolio = transaction.portfolio {
            portfolio.transactions.removeAll { $0.id == transaction.id }
            await recalculatePortfolioFromTransactions(portfolio)
        }
        
        context.delete(transaction)
        try context.save()
    }
    
    // MARK: - Price Updates
    
    private func startPriceUpdates() async {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateAllPortfolioValues()
            }
        }
    }
    
    private func updateAllPortfolioValues() async {
        for portfolio in portfolios {
            await updatePortfolioValue(portfolio)
        }
    }
    
    private func updatePortfolioValue(_ portfolio: Portfolio) async {
        for holding in portfolio.holdings {
            if let currency = holding.currency {
                let streamKey = "\(currency.symbol)-USD"
                if let streamPrice = priceStreamService.prices[streamKey]?.price {
                    holding.updatePrice(streamPrice)
                }
            }
        }
        
        portfolio.updateCalculations()
        
        if let context = modelContext {
            try? context.save()
        }
    }
    
    private func recalculatePortfolioFromTransactions(_ portfolio: Portfolio) async {
        var holdingMap: [String: Holding] = [:]
        
        for transaction in portfolio.transactions.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let currency = transaction.currency else { continue }
            
            let currencyId = currency.id
            if holdingMap[currencyId] == nil {
                holdingMap[currencyId] = Holding(currency: currency, quantity: 0, averageCost: 0, portfolio: portfolio)
            }
            
            if let holding = holdingMap[currencyId] {
                holding.addTransaction(transaction)
            }
        }
        
        portfolio.holdings = Array(holdingMap.values.filter { $0.quantity > 0 })
        portfolio.updateCalculations()
        
        if let context = modelContext {
            try? context.save()
        }
    }
    
    // MARK: - Analytics
    
    func getPortfolioPerformance(_ portfolio: Portfolio, period: AnalyticsPeriod) async -> PortfolioPerformance {
        let endDate = Date()
        let startDate = period.startDate(from: endDate)
        
        let relevantTransactions = portfolio.transactions.filter {
            $0.timestamp >= startDate && $0.timestamp <= endDate
        }
        
        let totalInvested = relevantTransactions
            .filter { $0.type == .buy }
            .reduce(0) { $0 + $1.totalAmount }
        
        let totalWithdrawn = relevantTransactions
            .filter { $0.type == .sell }
            .reduce(0) { $0 + $1.totalAmount }
        
        let netInvestment = totalInvested - totalWithdrawn
        let currentValue = portfolio.totalValue
        let profitLoss = currentValue - netInvestment
        let profitLossPercent = netInvestment > 0 ? (profitLoss / netInvestment) * 100 : 0
        
        return PortfolioPerformance(
            period: period,
            startValue: netInvestment,
            endValue: currentValue,
            profitLoss: profitLoss,
            profitLossPercent: profitLossPercent,
            totalInvested: totalInvested,
            totalWithdrawn: totalWithdrawn
        )
    }
    
    func getTopPerformers(_ portfolio: Portfolio, limit: Int = 5) -> [Holding] {
        return portfolio.holdings
            .sorted { $0.profitLossPercent > $1.profitLossPercent }
            .prefix(limit)
            .map { $0 }
    }
    
    func getWorstPerformers(_ portfolio: Portfolio, limit: Int = 5) -> [Holding] {
        return portfolio.holdings
            .sorted { $0.profitLossPercent < $1.profitLossPercent }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Supporting Models

struct PortfolioPerformance {
    let period: AnalyticsPeriod
    let startValue: Double
    let endValue: Double
    let profitLoss: Double
    let profitLossPercent: Double
    let totalInvested: Double
    let totalWithdrawn: Double
    
    var profitLossFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.positivePrefix = "+"
        return formatter.string(from: NSNumber(value: profitLoss)) ?? "$0.00"
    }
    
    var isPositive: Bool {
        return profitLoss >= 0
    }
}

enum AnalyticsPeriod: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case year = "1Y"
    case all = "All"
    
    var displayName: String { rawValue }
    
    func startDate(from endDate: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: endDate) ?? endDate
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .all:
            return Date.distantPast
        }
    }
}

enum PortfolioError: LocalizedError {
    case contextNotAvailable
    case portfolioNotFound
    case holdingNotFound
    case insufficientBalance
    case invalidTransaction
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .portfolioNotFound:
            return "Portfolio not found"
        case .holdingNotFound:
            return "Holding not found"
        case .insufficientBalance:
            return "Insufficient balance for this transaction"
        case .invalidTransaction:
            return "Invalid transaction data"
        }
    }
}