//
//  AddCurrencyView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct AddCurrencyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CurrencySearchService.self) private var searchService
    @State private var viewModel = AddCurrencyViewModel()
    
    @State private var searchText = ""
    @State private var selectedCategory: CurrencyCategory = .popular
    
    enum CurrencyCategory: String, CaseIterable {
        case popular = "Popular"
        case trending = "Trending"
        case all = "All"
        case recent = "Recent"
        
        var systemImage: String {
            switch self {
            case .popular: return "star.fill"
            case .trending: return "chart.line.uptrend.xyaxis"
            case .all: return "list.bullet"
            case .recent: return "clock.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Category Selector
                categorySelector
                
                // Results List
                currencyList
            }
            .navigationTitle("Add Currency")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                viewModel.setModelContext(modelContext)
                viewModel.clearDuplicatesAndResetDatabase() // Clean up any duplicates on startup
                await searchService.loadInitialData()
            }
        }
    }
    
    private var searchBar: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search currencies...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        searchService.searchCurrencies(newValue)
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchService.searchCurrencies("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CurrencyCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        searchText = ""
                        Task {
                            await loadCategoryData(category)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.systemImage)
                                .font(.caption)
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedCategory == category 
                                ? Color.accentColor 
                                : Color(.systemGray5)
                        )
                        .foregroundColor(
                            selectedCategory == category 
                                ? .white 
                                : .primary
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var currencyList: some View {
        Group {
            if searchService.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading currencies...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchService.searchResults.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(currentCurrencies, id: \.id) { currency in
                        CurrencyRow(
                            currency: currency,
                            onTap: {
                                addCurrencyPair(currency: currency)
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No currencies found")
                .font(.headline)
            
            Text("Try adjusting your search or browse different categories")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var currentCurrencies: [AvailableCurrency] {
        if !searchText.isEmpty {
            return searchService.searchResults
        }
        
        switch selectedCategory {
        case .popular:
            return searchService.getTopCurrencies()
        case .trending:
            // This would be loaded async, for now show popular
            return searchService.getTopCurrencies()
        case .all:
            return searchService.availableCurrencies
        case .recent:
            return searchService.getRecentlyAdded()
        }
    }
    
    private func loadCategoryData(_ category: CurrencyCategory) async {
        switch category {
        case .trending:
            // Load trending currencies
            break
        default:
            break
        }
    }
    
    private func addCurrencyPair(currency: AvailableCurrency) {
        viewModel.addCurrencyPair(currency)
        dismiss()
    }
}

struct CurrencyRow: View {
    let currency: AvailableCurrency
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Currency Icon Placeholder
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(currency.symbol.prefix(1))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currency.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(currency.symbol)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let displaySymbol = currency.displaySymbol, displaySymbol != currency.symbol {
                        Text("• \(displaySymbol)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}


#Preview {
    AddCurrencyView()
        .modelContainer(for: [CurrencyPair.self], inMemory: true)
        .environment(CurrencySearchService.shared)
}