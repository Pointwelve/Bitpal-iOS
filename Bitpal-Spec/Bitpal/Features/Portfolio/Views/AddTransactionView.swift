//
//  AddTransactionView.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-18.
//

import SwiftUI
import SwiftData

/// Transaction entry form sheet
/// Per Constitution Principle II: Follows Liquid Glass design system
struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddTransactionViewModel()
    @State private var showCoinPicker = false
    @State private var errorMessage: String?

    /// Existing holdings for sell validation and coin ordering (FR-029)
    let existingHoldings: [Holding]

    /// Callback when transaction is saved
    var onSave: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                // Coin Selection
                coinSelectionSection

                // Transaction Type
                transactionTypeSection

                // Amount & Price
                amountSection

                // Date
                dateSection

                // Notes
                notesSection

                // Total Value Display
                if viewModel.totalValue > 0 {
                    totalValueSection
                }

                // Validation Error Display (T023)
                if let error = viewModel.validationError {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundColor(.lossRed)
                            .font(Typography.callout)
                    }
                }
            }
            .navigationTitle(viewModel.selectedCoinId == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .task {
                viewModel.configure(modelContext: modelContext)
            }
            .sheet(isPresented: $showCoinPicker) {
                coinPickerSheet
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var coinSelectionSection: some View {
        Section("Cryptocurrency") {
            Button {
                showCoinPicker = true
            } label: {
                HStack {
                    if let coin = viewModel.selectedCoin {
                        VStack(alignment: .leading) {
                            Text(coin.name)
                                .foregroundColor(.primary)
                            Text(coin.symbol.uppercased())
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Select Coin")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var transactionTypeSection: some View {
        Section("Transaction Type") {
            Picker("Type", selection: $viewModel.transactionType) {
                Text("Buy").tag(TransactionType.buy)
                Text("Sell").tag(TransactionType.sell)
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.transactionType) { _, newValue in
                // Update holding quantity for sell validation (FR-003)
                if newValue == .sell, let coinId = viewModel.selectedCoinId {
                    viewModel.currentHoldingQuantity = existingHoldings
                        .first { $0.id == coinId }?.totalAmount ?? 0
                }
            }
        }
    }

    private var amountSection: some View {
        Section("Details") {
            HStack {
                Text("Quantity")
                Spacer()
                TextField("0.0", text: $viewModel.amountString)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 150)
            }

            // T064: Sell All button (FR-030)
            if viewModel.transactionType == .sell && viewModel.currentHoldingQuantity > 0 {
                Button {
                    viewModel.amountString = "\(viewModel.currentHoldingQuantity)"
                } label: {
                    HStack {
                        Text("Sell All")
                        Spacer()
                        Text("\(viewModel.currentHoldingQuantity)")
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack {
                Text("Price per Coin")
                Spacer()
                Text("$")
                    .foregroundColor(.secondary)
                TextField("0.00", text: $viewModel.priceString)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
            }
        }
    }

    private var dateSection: some View {
        Section("Date") {
            DatePicker(
                "Transaction Date",
                selection: $viewModel.date,
                in: ...Date(),
                displayedComponents: .date
            )
        }
    }

    private var notesSection: some View {
        Section("Notes (Optional)") {
            TextField("Add notes...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var totalValueSection: some View {
        Section {
            HStack {
                Text("Total Value")
                    .font(Typography.headline)
                Spacer()
                Text(Formatters.formatCurrency(viewModel.totalValue))
                    .font(Typography.headline)
                    .foregroundColor(viewModel.transactionType == .buy ? .profitGreen : .lossRed)
            }
        }
    }

    // MARK: - Coin Picker (T024)

    /// Coin picker with owned coins first for sell type (FR-029)
    private var coinPickerSheet: some View {
        NavigationStack {
            CoinPickerView(
                ownedCoinIds: existingHoldings.map { $0.id }
            ) { coin in
                viewModel.selectedCoinId = coin.id
                viewModel.selectedCoin = Coin(
                    id: coin.id,
                    symbol: coin.symbol,
                    name: coin.name,
                    currentPrice: 0,
                    priceChange24h: 0,
                    lastUpdated: Date(),
                    marketCap: nil
                )

                // Update holding quantity for sell validation
                if viewModel.transactionType == .sell {
                    viewModel.currentHoldingQuantity = existingHoldings
                        .first { $0.id == coin.id }?.totalAmount ?? 0
                }

                showCoinPicker = false
            }
            .navigationTitle("Select Coin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCoinPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveTransaction() {
        Task {
            do {
                try await viewModel.saveTransaction()
                onSave?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AddTransactionView(existingHoldings: [])
}
