//
//  TransactionHistoryView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    let portfolio: Portfolio
    @Environment(PortfolioService.self) private var portfolioService
    
    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?
    @State private var showingEditTransaction = false
    
    private var filteredTransactions: [Transaction] {
        let filtered = portfolio.transactions.filter { transaction in
            let matchesFilter = selectedFilter == .all || transaction.type == selectedFilter.transactionType
            let matchesSearch = searchText.isEmpty || 
                transaction.currency?.name.localizedCaseInsensitiveContains(searchText) == true ||
                transaction.currency?.symbol.localizedCaseInsensitiveContains(searchText) == true ||
                transaction.exchange.localizedCaseInsensitiveContains(searchText)
            
            return matchesFilter && matchesSearch
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var groupedTransactions: [(String, [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            calendar.dateInterval(of: .day, for: transaction.timestamp)?.start ?? transaction.timestamp
        }
        
        return grouped.map { (date, transactions) in
            (DateFormatter.dayGroupFormatter.string(from: date), transactions.sorted { $0.timestamp > $1.timestamp })
        }.sorted { $0.0 > $1.0 }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search transactions...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.displayName,
                                    isSelected: selectedFilter == filter
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Transactions List
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    transactionsList
                }
            }
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(portfolio: portfolio)
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "No Transactions" : "No Results")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(searchText.isEmpty ? 
                     "Add your first transaction to start tracking your portfolio history" :
                     "No transactions match your search criteria")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button {
                    showingAddTransaction = true
                } label: {
                    Text("Add Transaction")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
            } else {
                Button {
                    searchText = ""
                } label: {
                    Text("Clear Search")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var transactionsList: some View {
        List {
            ForEach(groupedTransactions, id: \.0) { date, transactions in
                Section {
                    ForEach(transactions, id: \.id) { transaction in
                        TransactionHistoryRow(transaction: transaction)
                            .onTapGesture {
                                selectedTransaction = transaction
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    Task {
                                        try? await portfolioService.deleteTransaction(transaction)
                                    }
                                }
                            }
                    }
                } header: {
                    Text(date)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct TransactionHistoryRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Transaction Type Icon
            ZStack {
                Circle()
                    .fill(Color(transaction.typeColor).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.type.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(transaction.typeColor))
            }
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(transaction.typeDisplayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(transaction.symbol)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 8) {
                    Text("\(transaction.quantityFormatted) \(transaction.symbol)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !transaction.exchange.isEmpty {
                        Text("• \(transaction.exchange)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(transaction.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount and Price
            VStack(alignment: .trailing, spacing: 2) {
                if transaction.type != .transfer {
                    Text(transaction.totalAmountFormatted)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("@ \(transaction.priceFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(transaction.quantityFormatted) \(transaction.symbol)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(transaction.isIncoming ? "Received" : "Sent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if transaction.fee > 0 {
                    Text("Fee: \(transaction.fee.formatted(.currency(code: "USD")))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    DetailRow(title: "Type", value: transaction.typeDisplayName)
                    DetailRow(title: "Currency", value: transaction.currency?.name ?? "Unknown")
                    DetailRow(title: "Symbol", value: transaction.symbol)
                    DetailRow(title: "Quantity", value: transaction.quantityFormatted)
                    
                    if transaction.type != .transfer {
                        DetailRow(title: "Price", value: transaction.priceFormatted)
                        DetailRow(title: "Total Amount", value: transaction.totalAmountFormatted)
                    }
                    
                    if transaction.fee > 0 {
                        DetailRow(title: "Fee", value: transaction.fee.formatted(.currency(code: "USD")))
                    }
                    
                    DetailRow(title: "Date", value: transaction.timestamp.formatted(.dateTime.weekday(.wide).month().day().year().hour().minute()))
                }
                
                if !transaction.exchange.isEmpty {
                    Section("Exchange") {
                        DetailRow(title: "Exchange", value: transaction.exchange)
                    }
                }
                
                if !transaction.notes.isEmpty {
                    Section("Notes") {
                        Text(transaction.notes)
                            .font(.body)
                    }
                }
                
                if !transaction.txHash.isEmpty {
                    Section("Blockchain") {
                        DetailRow(title: "Transaction Hash", value: transaction.txHash)
                    }
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

enum TransactionFilter: CaseIterable {
    case all
    case buy
    case sell
    case transfer
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .transfer: return "Transfer"
        }
    }
    
    var transactionType: TransactionType? {
        switch self {
        case .all: return nil
        case .buy: return .buy
        case .sell: return .sell
        case .transfer: return .transfer
        }
    }
}

extension DateFormatter {
    static let dayGroupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    let samplePortfolio = Portfolio(name: "Test Portfolio")
    
    TransactionHistoryView(portfolio: samplePortfolio)
        .environment(PortfolioService.shared)
}