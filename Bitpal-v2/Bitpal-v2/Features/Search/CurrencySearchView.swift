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
    @State private var searchService = CurrencySearchService.shared
    
    private var displayedCurrencies: [Currency] {
        // Convert AvailableCurrency to Currency for display
        let availableCurrencies = searchText.isEmpty ? 
            searchService.getTopCurrencies() : 
            searchService.searchResults
            
        return availableCurrencies.map { availableCurrency in
            Currency(
                id: availableCurrency.id,
                name: availableCurrency.name,
                symbol: availableCurrency.symbol,
                displaySymbol: availableCurrency.displaySymbol
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                CurrencySearchBar(text: $searchText)
                    .padding(.horizontal)
                    .onChange(of: searchText) { oldValue, newValue in
                        searchService.searchCurrencies(newValue)
                    }
                
                // Currency List
                List(displayedCurrencies, id: \.id) { currency in
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