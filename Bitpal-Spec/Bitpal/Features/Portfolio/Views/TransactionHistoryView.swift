//
//  TransactionHistoryView.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import SwiftUI
import SwiftData

// Enable UUID to work with .sheet(item:) pattern
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

/// Transaction history for a specific holding
/// Per Constitution Principle II: Follows Liquid Glass design system
struct TransactionHistoryView: View {
    @Environment(\.modelContext) private var modelContext

    let coinId: String
    let coinName: String

    // T045: Query transactions filtered by coinId, sorted by date descending
    @Query private var transactions: [Transaction]

    @State private var selectedTransactionId: UUID?
    @State private var showDeleteConfirmation = false
    @State private var transactionToDelete: Transaction?
    @State private var errorMessage: String?

    init(coinId: String, coinName: String) {
        self.coinId = coinId
        self.coinName = coinName

        // Filter transactions for this coin and sort by date descending
        let predicate = #Predicate<Transaction> { transaction in
            transaction.coinId == coinId
        }
        _transactions = Query(
            filter: predicate,
            sort: [SortDescriptor(\Transaction.date, order: .reverse)]
        )
    }

    var body: some View {
        Group {
            if transactions.isEmpty {
                emptyStateView
            } else {
                transactionList
            }
        }
        .navigationTitle(coinName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTransactionId) { id in
            // Re-fetch transaction from current @Query context using item-based sheet pattern
            if let transaction = transactions.first(where: { $0.id == id }) {
                EditTransactionView(transaction: transaction) {
                    selectedTransactionId = nil  // Dismiss sheet
                }
            } else {
                ContentUnavailableView(
                    "Transaction Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("The transaction may have been deleted.")
                )
            }
        }
        // T054: Delete confirmation alert
        .alert("Delete Transaction", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                transactionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let transaction = transactionToDelete {
                    deleteTransaction(transaction)
                }
            }
        } message: {
            Text("Delete this transaction? This will affect your holdings.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.standard) {
                ForEach(transactions) { transaction in
                    // T052: Tap to open edit sheet (item-based sheet auto-presents)
                    TransactionRowView(transaction: transaction)
                        .onTapGesture {
                            selectedTransactionId = transaction.id
                        }
                        // T053: Swipe to delete
                        .contextMenu {
                            Button(role: .destructive) {
                                transactionToDelete = transaction
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.large) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)

            Text("No Transactions")
                .font(Typography.title2)

            Text("Transaction history for \(coinName) will appear here.")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xlarge)
        }
        .padding()
    }

    // MARK: - Actions

    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete transaction: \(error.localizedDescription)"
        }

        transactionToDelete = nil
    }
}

// MARK: - Transaction Row View (T044)

/// Individual transaction display row
/// Per Constitution Principle II: Uses LiquidGlassCard
struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Header: Type and Date
                HStack {
                    // Type indicator with color
                    HStack(spacing: Spacing.tiny) {
                        Image(systemName: transaction.type == .buy ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(typeColor)
                        Text(transaction.type.displayName)
                            .font(Typography.headline)
                            .foregroundColor(typeColor)
                    }

                    Spacer()

                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()

                // Details
                HStack {
                    // Quantity
                    VStack(alignment: .leading, spacing: Spacing.tiny) {
                        Text("Quantity")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(formatQuantity(transaction.amount))
                            .font(Typography.body)
                    }

                    Spacer()

                    // Price per coin
                    VStack(alignment: .center, spacing: Spacing.tiny) {
                        Text("Price")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(Formatters.formatCurrency(transaction.pricePerCoin))
                            .font(Typography.body)
                    }

                    Spacer()

                    // Total value
                    VStack(alignment: .trailing, spacing: Spacing.tiny) {
                        Text("Total")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                        Text(Formatters.formatCurrency(transaction.amount * transaction.pricePerCoin))
                            .font(Typography.body)
                            .fontWeight(.medium)
                    }
                }

                // Notes (if present)
                if let notes = transaction.notes, !notes.isEmpty {
                    Divider()
                    Text(notes)
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                        .lineLimit(3)
                }
            }
        }
    }

    // MARK: - Helpers

    private var typeColor: Color {
        transaction.type == .buy ? .profitGreen : .lossRed
    }

    private func formatQuantity(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8

        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

// MARK: - Edit Transaction View (T049, T052)

/// Sheet for editing an existing transaction
struct EditTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction
    var onSave: (() -> Void)?

    @State private var transactionType: TransactionType
    @State private var amountString: String
    @State private var priceString: String
    @State private var date: Date
    @State private var notes: String
    @State private var errorMessage: String?
    @State private var isSaving = false

    init(transaction: Transaction, onSave: (() -> Void)? = nil) {
        self.transaction = transaction
        self.onSave = onSave

        // Prepopulate form with existing values
        _transactionType = State(initialValue: transaction.type)
        _amountString = State(initialValue: "\(transaction.amount)")
        _priceString = State(initialValue: "\(transaction.pricePerCoin)")
        _date = State(initialValue: transaction.date)
        _notes = State(initialValue: transaction.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Transaction Type
                Section("Transaction Type") {
                    Picker("Type", selection: $transactionType) {
                        Text("Buy").tag(TransactionType.buy)
                        Text("Sell").tag(TransactionType.sell)
                    }
                    .pickerStyle(.segmented)
                }

                // Amount & Price
                Section("Details") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("0.0", text: $amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 150)
                    }

                    HStack {
                        Text("Price per Coin")
                        Spacer()
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $priceString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 140)
                    }
                }

                // Date
                Section("Date") {
                    DatePicker(
                        "Transaction Date",
                        selection: $date,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                // Notes
                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Total Value Display
                if let total = totalValue, total > 0 {
                    Section {
                        HStack {
                            Text("Total Value")
                                .font(Typography.headline)
                            Spacer()
                            Text(Formatters.formatCurrency(total))
                                .font(Typography.headline)
                                .foregroundColor(transactionType == .buy ? .profitGreen : .lossRed)
                        }
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Computed Properties

    private var amount: Decimal? {
        Decimal(string: amountString)
    }

    private var price: Decimal? {
        Decimal(string: priceString)
    }

    private var totalValue: Decimal? {
        guard let amt = amount, let prc = price else { return nil }
        return amt * prc
    }

    private var isValid: Bool {
        guard let amt = amount, let prc = price else { return false }
        return amt > 0 && prc > 0 && date <= Date()
    }

    // MARK: - Actions

    private func saveChanges() {
        guard let amt = amount, let prc = price else {
            errorMessage = "Invalid amount or price"
            return
        }

        isSaving = true

        // Update transaction properties
        transaction.type = transactionType
        transaction.amount = amt
        transaction.pricePerCoin = prc
        transaction.date = date
        transaction.notes = notes.isEmpty ? nil : notes

        do {
            try modelContext.save()
            onSave?()
            dismiss()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        TransactionHistoryView(coinId: "bitcoin", coinName: "Bitcoin")
    }
}
