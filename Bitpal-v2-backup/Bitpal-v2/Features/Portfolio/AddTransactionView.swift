//
//  AddTransactionView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    let portfolio: Portfolio
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioService.self) private var portfolioService
    @Environment(CurrencySearchService.self) private var searchService
    
    @State private var selectedCurrency: Currency?
    @State private var transactionType: TransactionType = .buy
    @State private var quantity: String = ""
    @State private var price: String = ""
    @State private var fee: String = ""
    @State private var exchange: String = ""
    @State private var notes: String = ""
    @State private var transactionDate = Date()
    @State private var showingCurrencySearch = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        guard let _ = selectedCurrency,
              let quantityValue = Double(quantity), quantityValue > 0,
              let priceValue = Double(price), priceValue > 0 else {
            return false
        }
        return true
    }
    
    private var totalAmount: Double {
        guard let quantityValue = Double(quantity),
              let priceValue = Double(price) else {
            return 0
        }
        return quantityValue * priceValue
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    // Currency Selection
                    Button {
                        showingCurrencySearch = true
                    } label: {
                        HStack {
                            Text("Currency")
                            Spacer()
                            if let currency = selectedCurrency {
                                HStack {
                                    Text(currency.symbol)
                                        .foregroundColor(.primary)
                                    Text(currency.name)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Select Currency")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Transaction Type
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Quantity
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("0.00", text: $quantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        if let currency = selectedCurrency {
                            Text(currency.symbol)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Price (for buy/sell transactions)
                    if transactionType != .transfer {
                        HStack {
                            Text("Price")
                            Spacer()
                            TextField("0.00", text: $price)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("USD")
                                .foregroundColor(.secondary)
                        }
                        
                        // Total Amount
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(totalAmount.formatted(.currency(code: "USD")))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Transaction Date
                    DatePicker("Date", selection: $transactionDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Additional Information") {
                    // Fee
                    HStack {
                        Text("Fee")
                        Spacer()
                        TextField("0.00", text: $fee)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("USD")
                            .foregroundColor(.secondary)
                    }
                    
                    // Exchange
                    TextField("Exchange", text: $exchange)
                    
                    // Notes
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            await addTransaction()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .sheet(isPresented: $showingCurrencySearch) {
                CurrencySearchView(selectedCurrency: $selectedCurrency)
            }
        }
    }
    
    private func addTransaction() async {
        guard let currency = selectedCurrency,
              let quantityValue = Double(quantity),
              let priceValue = Double(price) else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let feeValue = Double(fee) ?? 0.0
            
            _ = try await portfolioService.addTransaction(
                to: portfolio,
                currency: currency,
                type: transactionType,
                quantity: quantityValue,
                price: priceValue,
                fee: feeValue,
                exchange: exchange,
                notes: notes
            )
            
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct AddHoldingView: View {
    let portfolio: Portfolio
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioService.self) private var portfolioService
    
    @State private var selectedCurrency: Currency?
    @State private var quantity: String = ""
    @State private var averageCost: String = ""
    @State private var showingCurrencySearch = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        guard let _ = selectedCurrency,
              let quantityValue = Double(quantity), quantityValue > 0,
              let costValue = Double(averageCost), costValue > 0 else {
            return false
        }
        return true
    }
    
    private var totalCost: Double {
        guard let quantityValue = Double(quantity),
              let costValue = Double(averageCost) else {
            return 0
        }
        return quantityValue * costValue
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Holding Details") {
                    // Currency Selection
                    Button {
                        showingCurrencySearch = true
                    } label: {
                        HStack {
                            Text("Currency")
                            Spacer()
                            if let currency = selectedCurrency {
                                HStack {
                                    Text(currency.symbol)
                                        .foregroundColor(.primary)
                                    Text(currency.name)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Select Currency")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Quantity
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("0.00", text: $quantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        if let currency = selectedCurrency {
                            Text(currency.symbol)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Average Cost
                    HStack {
                        Text("Average Cost")
                        Spacer()
                        TextField("0.00", text: $averageCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("USD")
                            .foregroundColor(.secondary)
                    }
                    
                    // Total Cost
                    HStack {
                        Text("Total Cost")
                        Spacer()
                        Text(totalCost.formatted(.currency(code: "USD")))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            await addHolding()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .sheet(isPresented: $showingCurrencySearch) {
                CurrencySearchView(selectedCurrency: $selectedCurrency)
            }
        }
    }
    
    private func addHolding() async {
        guard let currency = selectedCurrency,
              let quantityValue = Double(quantity),
              let costValue = Double(averageCost) else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await portfolioService.addHolding(
                to: portfolio,
                currency: currency,
                quantity: quantityValue,
                averageCost: costValue
            )
            
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct CreatePortfolioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PortfolioService.self) private var portfolioService
    
    @State private var portfolioName: String = ""
    @State private var isDefault: Bool = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var isFormValid: Bool {
        !portfolioName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Portfolio Details") {
                    TextField("Portfolio Name", text: $portfolioName)
                    
                    Toggle("Set as Default", isOn: $isDefault)
                }
                
                Section {
                    Text("Your default portfolio will be displayed first and used for quick actions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await createPortfolio()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private func createPortfolio() async {
        let name = portfolioName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "Please enter a portfolio name"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await portfolioService.createPortfolio(name: name, isDefault: isDefault)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    let samplePortfolio = Portfolio(name: "Test Portfolio")
    
    AddTransactionView(portfolio: samplePortfolio)
        .environment(PortfolioService.shared)
        .environment(CurrencySearchService.shared)
}