//
//  PortfolioView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct PortfolioView: View {
    @Environment(PortfolioService.self) private var portfolioService
    @Query private var portfolios: [Portfolio]
    @State private var selectedPortfolio: Portfolio?
    @State private var showingAddHolding = false
    @State private var showingAddTransaction = false
    @State private var showingCreatePortfolio = false
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var portfolioPerformance: PortfolioPerformance?
    
    var currentPortfolio: Portfolio? {
        selectedPortfolio ?? portfolios.first { $0.isDefault } ?? portfolios.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let portfolio = currentPortfolio {
                        // Portfolio Header
                        portfolioHeader(portfolio)
                        
                        // Performance Chart
                        performanceSection(portfolio)
                        
                        // Holdings List
                        holdingsSection(portfolio)
                        
                        // Recent Transactions
                        recentTransactionsSection(portfolio)
                    } else {
                        emptyPortfolioView
                    }
                }
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    portfolioSelector
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddHolding = true
                        } label: {
                            Label("Add Holding", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingAddTransaction = true
                        } label: {
                            Label("Add Transaction", systemImage: "arrow.left.arrow.right.circle")
                        }
                        
                        Button {
                            showingCreatePortfolio = true
                        } label: {
                            Label("Create Portfolio", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await portfolioService.loadPortfolios()
            }
            .sheet(isPresented: $showingAddHolding) {
                if let portfolio = currentPortfolio {
                    AddHoldingView(portfolio: portfolio)
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                if let portfolio = currentPortfolio {
                    AddTransactionView(portfolio: portfolio)
                }
            }
            .sheet(isPresented: $showingCreatePortfolio) {
                CreatePortfolioView()
            }
            .task {
                if let portfolio = currentPortfolio {
                    await loadPerformanceData(portfolio)
                }
            }
            .onChange(of: selectedPortfolio) { _, newPortfolio in
                if let portfolio = newPortfolio {
                    Task {
                        await loadPerformanceData(portfolio)
                    }
                }
            }
        }
    }
    
    private var portfolioSelector: some View {
        Menu {
            ForEach(portfolios, id: \.id) { portfolio in
                Button {
                    selectedPortfolio = portfolio
                } label: {
                    HStack {
                        Text(portfolio.name)
                        if portfolio.isDefault {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(currentPortfolio?.name ?? "Portfolio")
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
    }
    
    private func portfolioHeader(_ portfolio: Portfolio) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(portfolio.totalValueFormatted)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: portfolio.isPositivePerformance ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .foregroundColor(portfolio.isPositivePerformance ? .green : .red)
                        
                        Text(portfolio.totalProfitLossFormatted)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(portfolio.isPositivePerformance ? .green : .red)
                    }
                    
                    Text("(\(portfolio.totalProfitLossPercent >= 0 ? "+" : "")\(String(format: "%.2f", portfolio.totalProfitLossPercent))%)")
                        .font(.caption)
                        .foregroundColor(portfolio.isPositivePerformance ? .green : .red)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(portfolio.totalCost.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Holdings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(portfolio.holdings.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func performanceSection(_ portfolio: Portfolio) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Performance")
                    .font(.headline)
                
                Spacer()
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal)
            
            if let performance = portfolioPerformance {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Period P&L")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(performance.profitLossFormatted)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(performance.isPositive ? .green : .red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Return")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(performance.profitLossPercent >= 0 ? "+" : "")\(String(format: "%.2f", performance.profitLossPercent))%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(performance.isPositive ? .green : .red)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Invested")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(performance.totalInvested.formatted(.currency(code: "USD")))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Withdrawn")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(performance.totalWithdrawn.formatted(.currency(code: "USD")))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadPerformanceData(portfolio)
            }
        }
    }
    
    private func holdingsSection(_ portfolio: Portfolio) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Holdings")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingAddHolding = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            
            if portfolio.holdings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "briefcase")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Holdings")
                        .font(.headline)
                    
                    Text("Add your first cryptocurrency holding to start tracking your portfolio")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showingAddHolding = true
                    } label: {
                        Text("Add Holding")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(portfolio.holdings, id: \.id) { holding in
                        HoldingRow(holding: holding)
                        
                        if holding.id != portfolio.holdings.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func recentTransactionsSection(_ portfolio: Portfolio) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    TransactionHistoryView(portfolio: portfolio)
                } label: {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            
            if portfolio.transactions.isEmpty {
                VStack(spacing: 12) {
                    Text("No Transactions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Text("Add Transaction")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(portfolio.transactions.sorted { $0.timestamp > $1.timestamp }.prefix(5)), id: \.id) { transaction in
                        TransactionRow(transaction: transaction)
                        
                        if transaction.id != portfolio.transactions.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyPortfolioView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Portfolio")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create your first portfolio to start tracking your cryptocurrency investments")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingCreatePortfolio = true
            } label: {
                Text("Create Portfolio")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private func loadPerformanceData(_ portfolio: Portfolio) async {
        portfolioPerformance = await portfolioService.getPortfolioPerformance(portfolio, period: selectedPeriod)
    }
}

// MARK: - Supporting Views

struct HoldingRow: View {
    let holding: Holding
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: "https://cryptoicons.org/api/icon/\(holding.symbol.lowercased())/200")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Text(holding.symbol.prefix(1))
                            .font(.caption)
                            .fontWeight(.bold)
                    }
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(holding.quantityFormatted) \(holding.symbol)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.currentValueFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: holding.profitLoss >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .foregroundColor(holding.profitLoss >= 0 ? .green : .red)
                    
                    Text(holding.profitLossFormatted)
                        .font(.caption)
                        .foregroundColor(holding.profitLoss >= 0 ? .green : .red)
                }
            }
        }
        .padding()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.type.systemImage)
                .font(.title2)
                .foregroundColor(Color(transaction.typeColor))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.typeDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(transaction.quantityFormatted) \(transaction.symbol)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.totalAmountFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    PortfolioView()
        .environment(PortfolioService.shared)
        .modelContainer(for: [Portfolio.self, Holding.self, Transaction.self], inMemory: true)
}