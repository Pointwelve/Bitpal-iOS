//
//  CreateAlertView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct CreateAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AlertService.self) private var alertService
    @Query private var currencyPairs: [CurrencyPair]
    
    @State private var selectedCurrencyPair: CurrencyPair?
    @State private var selectedComparison: AlertComparison = .above
    @State private var targetPriceText = ""
    @State private var isEnabled = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCreating = false
    
    private var targetPrice: Double {
        Double(targetPriceText) ?? 0
    }
    
    private var isValidInput: Bool {
        selectedCurrencyPair != nil && targetPrice > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Currency Pair") {
                    if currencyPairs.isEmpty {
                        Text("No currency pairs available. Add some to your watchlist first.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Select Currency Pair", selection: $selectedCurrencyPair) {
                            Text("Select a pair")
                                .tag(nil as CurrencyPair?)
                            
                            ForEach(currencyPairs, id: \.id) { pair in
                                HStack {
                                    Text(pair.displayName)
                                    Spacer()
                                    Text(pair.currentPrice.formatted(.currency(code: "USD")))
                                        .foregroundColor(.secondary)
                                }
                                .tag(pair as CurrencyPair?)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        if let pair = selectedCurrencyPair {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Price")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(pair.currentPrice.formatted(.currency(code: "USD")))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(pair.priceChange24h >= 0 ? "+\(pair.priceChange24h.formatted(.currency(code: "USD")))" : pair.priceChange24h.formatted(.currency(code: "USD")))
                                            .font(.caption)
                                            .foregroundColor(pair.priceChange24h >= 0 ? .green : .red)
                                        
                                        Text("\(pair.priceChangePercent24h >= 0 ? "+" : "")\(String(format: "%.2f", pair.priceChangePercent24h))%")
                                            .font(.caption)
                                            .foregroundColor(pair.priceChangePercent24h >= 0 ? .green : .red)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Section("Alert Condition") {
                    Picker("Comparison", selection: $selectedComparison) {
                        ForEach(AlertComparison.allCases, id: \.self) { comparison in
                            Label(comparison.displayName, systemImage: comparison.systemImage)
                                .tag(comparison)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("Target Price")
                        Spacer()
                        TextField("0.00", text: $targetPriceText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 120)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    if let pair = selectedCurrencyPair, targetPrice > 0 {
                        let difference = targetPrice - pair.currentPrice
                        let percentDifference = (difference / pair.currentPrice) * 100
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Difference:")
                                Spacer()
                                Text("\(difference >= 0 ? "+" : "")\(difference.formatted(.currency(code: "USD")))")
                                    .foregroundColor(difference >= 0 ? .green : .red)
                            }
                            .font(.caption)
                            
                            HStack {
                                Text("Percentage:")
                                Spacer()
                                Text("\(percentDifference >= 0 ? "+" : "")\(String(format: "%.2f", percentDifference))%")
                                    .foregroundColor(percentDifference >= 0 ? .green : .red)
                            }
                            .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Section("Settings") {
                    Toggle("Enable Alert", isOn: $isEnabled)
                }
                
                if let pair = selectedCurrencyPair, targetPrice > 0 {
                    Section("Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Alert Summary")
                                .font(.headline)
                            
                            Text("You will be notified when \(pair.displayName) goes \(selectedComparison.displayName.lowercased()) \(targetPrice.formatted(.currency(code: "USD")))")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Create Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createAlert()
                    }
                    .disabled(!isValidInput || isCreating)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Auto-select first currency pair if only one available
                if currencyPairs.count == 1 {
                    selectedCurrencyPair = currencyPairs.first
                }
            }
        }
    }
    
    private func createAlert() {
        guard let currencyPair = selectedCurrencyPair else { return }
        
        isCreating = true
        
        Task {
            do {
                try await alertService.createAlert(
                    for: currencyPair,
                    comparison: selectedComparison,
                    targetPrice: targetPrice,
                    isEnabled: isEnabled
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isCreating = false
                }
            }
        }
    }
}

// MARK: - Supporting Extensions

extension AlertComparison {
    var systemImage: String {
        switch self {
        case .above:
            return "arrow.up.circle"
        case .below:
            return "arrow.down.circle"
        }
    }
}

#Preview {
    CreateAlertView()
        .modelContainer(for: [Alert.self, CurrencyPair.self], inMemory: true)
        .environment(AlertService.shared)
}