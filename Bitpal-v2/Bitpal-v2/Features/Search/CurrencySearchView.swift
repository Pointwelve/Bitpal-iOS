//
//  CurrencySearchView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct CurrencySearchView: View {
    @Binding var selectedCurrency: Currency?
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    
    // Mock currencies for now - in real implementation this would come from the search service
    private let sampleCurrencies = [
        Currency.bitcoin(),
        Currency.ethereum(),
        Currency.usd(),
        Currency(id: "bnb", name: "Binance Coin", symbol: "BNB"),
        Currency(id: "ada", name: "Cardano", symbol: "ADA"),
        Currency(id: "sol", name: "Solana", symbol: "SOL"),
        Currency(id: "matic", name: "Polygon", symbol: "MATIC"),
        Currency(id: "dot", name: "Polkadot", symbol: "DOT")
    ]
    
    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return sampleCurrencies
        } else {
            return sampleCurrencies.filter { currency in
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                CurrencySearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Currency List
                List(filteredCurrencies, id: \.id) { currency in
                    CurrencySelectionRow(currency: currency) {
                        selectedCurrency = currency
                        dismiss()
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CurrencySearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search currencies...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 8)
    }
}

struct CurrencySelectionRow: View {
    let currency: Currency
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currency.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(currency.symbol.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(currency.displaySymbol)
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CurrencySearchView(selectedCurrency: .constant(nil))
}