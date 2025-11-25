//
//  AdvancedSearchView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct AdvancedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AdvancedSearchService.self) private var searchService
    
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @State private var selectedSort: SortOption = .relevance
    @State private var selectedOrder: SortOrder = .descending
    @State private var priceRange: ClosedRange<Double> = 0...1000000
    @State private var marketCapRange: ClosedRange<Double> = 0...5000000000000
    @State private var volumeRange: ClosedRange<Double> = 0...100000000000
    @State private var changeRange: ClosedRange<Double> = -100...100
    @State private var selectedExchanges: Set<String> = []
    @State private var showOnlyFavorites = false
    @State private var showOnlyWithAlerts = false
    @State private var minRank: Double = 1
    @State private var maxRank: Double = 500
    @State private var isSearching = false
    @State private var searchResults: [SearchResult] = []
    @State private var showingFilters = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Header
                searchHeader
                
                // Quick Filters
                quickFilters
                
                // Results
                if isSearching {
                    searchingView
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    emptyResultsView
                } else if searchResults.isEmpty {
                    emptyStateView
                } else {
                    resultsListView
                }
            }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                AdvancedFiltersView(
                    priceRange: $priceRange,
                    marketCapRange: $marketCapRange,
                    volumeRange: $volumeRange,
                    changeRange: $changeRange,
                    selectedExchanges: $selectedExchanges,
                    showOnlyFavorites: $showOnlyFavorites,
                    showOnlyWithAlerts: $showOnlyWithAlerts,
                    minRank: $minRank,
                    maxRank: $maxRank
                )
            }
            .task {
                await performSearch()
            }
            .onChange(of: searchText) { _, _ in
                Task {
                    await performSearch()
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                Task {
                    await performSearch()
                }
            }
            .onChange(of: selectedSort) { _, _ in
                Task {
                    await performSearch()
                }
            }
        }
    }
    
    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search cryptocurrencies, exchanges, news...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            HStack {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(SearchCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                
                Spacer()
                
                Menu {
                    Picker("Sort", selection: $selectedSort) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Label(option.displayName, systemImage: option.systemImage).tag(option)
                        }
                    }
                    
                    Picker("Order", selection: $selectedOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Label(order.displayName, systemImage: order.systemImage).tag(order)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedSort.systemImage)
                        Image(systemName: selectedOrder.systemImage)
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "Favorites",
                    isSelected: showOnlyFavorites
                ) {
                    showOnlyFavorites.toggle()
                    Task { await performSearch() }
                }
                
                FilterChip(
                    title: "With Alerts",
                    isSelected: showOnlyWithAlerts
                ) {
                    showOnlyWithAlerts.toggle()
                    Task { await performSearch() }
                }
                
                FilterChip(
                    title: "Top 100",
                    isSelected: maxRank <= 100
                ) {
                    if maxRank <= 100 {
                        maxRank = 500
                    } else {
                        maxRank = 100
                    }
                    Task { await performSearch() }
                }
                
                FilterChip(
                    title: "Gainers",
                    isSelected: changeRange.lowerBound > 0
                ) {
                    if changeRange.lowerBound > 0 {
                        changeRange = -100...100
                    } else {
                        changeRange = 0...100
                    }
                    Task { await performSearch() }
                }
                
                FilterChip(
                    title: "Losers",
                    isSelected: changeRange.upperBound < 0
                ) {
                    if changeRange.upperBound < 0 {
                        changeRange = -100...100
                    } else {
                        changeRange = -100...0
                    }
                    Task { await performSearch() }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private var searchingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Try adjusting your search terms or filters")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                clearFilters()
            } label: {
                Text("Clear Filters")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Advanced Search")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Search for cryptocurrencies, exchanges, and market data with advanced filters")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 8) {
                Text("Try searching for:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    SuggestionChip(text: "Bitcoin") {
                        searchText = "Bitcoin"
                    }
                    SuggestionChip(text: "Ethereum") {
                        searchText = "Ethereum"
                    }
                    SuggestionChip(text: "DeFi") {
                        searchText = "DeFi"
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsListView: some View {
        List {
            ForEach(searchResults, id: \.id) { result in
                SearchResultRow(result: result)
                    .onTapGesture {
                        handleResultSelection(result)
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let searchParams = AdvancedSearchParameters(
            query: searchText,
            category: selectedCategory,
            sortBy: selectedSort,
            sortOrder: selectedOrder,
            priceRange: priceRange,
            marketCapRange: marketCapRange,
            volumeRange: volumeRange,
            changeRange: changeRange,
            selectedExchanges: selectedExchanges,
            showOnlyFavorites: showOnlyFavorites,
            showOnlyWithAlerts: showOnlyWithAlerts,
            rankRange: Int(minRank)...Int(maxRank)
        )
        
        do {
            searchResults = try await searchService.performAdvancedSearch(parameters: searchParams)
        } catch {
            print("Search failed: \(error)")
            searchResults = []
        }
        
        isSearching = false
    }
    
    private func clearFilters() {
        priceRange = 0...1000000
        marketCapRange = 0...5000000000000
        volumeRange = 0...100000000000
        changeRange = -100...100
        selectedExchanges = []
        showOnlyFavorites = false
        showOnlyWithAlerts = false
        minRank = 1
        maxRank = 500
        
        Task {
            await performSearch()
        }
    }
    
    private func handleResultSelection(_ result: SearchResult) {
        // Navigate to appropriate detail view based on result type
        dismiss()
    }
}

struct AdvancedFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var priceRange: ClosedRange<Double>
    @Binding var marketCapRange: ClosedRange<Double>
    @Binding var volumeRange: ClosedRange<Double>
    @Binding var changeRange: ClosedRange<Double>
    @Binding var selectedExchanges: Set<String>
    @Binding var showOnlyFavorites: Bool
    @Binding var showOnlyWithAlerts: Bool
    @Binding var minRank: Double
    @Binding var maxRank: Double
    
    @State private var availableExchanges: [Exchange] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Price Range") {
                    VStack {
                        HStack {
                            Text("$\(String(format: "%.2f", priceRange.lowerBound))")
                            Spacer()
                            Text("$\(String(format: "%.2f", priceRange.upperBound))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        RangeSlider(
                            range: $priceRange,
                            bounds: 0...1000000,
                            step: 1000
                        )
                    }
                }
                
                Section("Market Cap Range") {
                    VStack {
                        HStack {
                            Text(formatLargeNumber(marketCapRange.lowerBound))
                            Spacer()
                            Text(formatLargeNumber(marketCapRange.upperBound))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        RangeSlider(
                            range: $marketCapRange,
                            bounds: 0...5000000000000,
                            step: 1000000000
                        )
                    }
                }
                
                Section("24h Volume Range") {
                    VStack {
                        HStack {
                            Text(formatLargeNumber(volumeRange.lowerBound))
                            Spacer()
                            Text(formatLargeNumber(volumeRange.upperBound))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        RangeSlider(
                            range: $volumeRange,
                            bounds: 0...100000000000,
                            step: 1000000000
                        )
                    }
                }
                
                Section("24h Change Range") {
                    VStack {
                        HStack {
                            Text("\(String(format: "%.1f", changeRange.lowerBound))%")
                            Spacer()
                            Text("\(String(format: "%.1f", changeRange.upperBound))%")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        RangeSlider(
                            range: $changeRange,
                            bounds: -100...100,
                            step: 1
                        )
                    }
                }
                
                Section("Rank Range") {
                    VStack {
                        HStack {
                            Text("#\(Int(minRank))")
                            Spacer()
                            Text("#\(Int(maxRank))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        RangeSlider(
                            range: Binding(
                                get: { minRank...maxRank },
                                set: { newRange in
                                    minRank = newRange.lowerBound
                                    maxRank = newRange.upperBound
                                }
                            ),
                            bounds: 1...500,
                            step: 1
                        )
                    }
                }
                
                Section("Exchanges") {
                    ForEach(availableExchanges, id: \.id) { exchange in
                        HStack {
                            Text(exchange.displayName)
                            Spacer()
                            if selectedExchanges.contains(exchange.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedExchanges.contains(exchange.id) {
                                selectedExchanges.remove(exchange.id)
                            } else {
                                selectedExchanges.insert(exchange.id)
                            }
                        }
                    }
                }
                
                Section("Additional Filters") {
                    Toggle("Favorites Only", isOn: $showOnlyFavorites)
                    Toggle("With Alerts Only", isOn: $showOnlyWithAlerts)
                }
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadAvailableExchanges()
            }
        }
    }
    
    private func resetFilters() {
        priceRange = 0...1000000
        marketCapRange = 0...5000000000000
        volumeRange = 0...100000000000
        changeRange = -100...100
        selectedExchanges = []
        showOnlyFavorites = false
        showOnlyWithAlerts = false
        minRank = 1
        maxRank = 500
    }
    
    private func loadAvailableExchanges() async {
        // Load from SwiftData or API
        availableExchanges = [
            Exchange(id: "COINDESK", name: "CoinDesk", displayName: "CoinDesk"),
            Exchange(id: "Coinbase", name: "Coinbase", displayName: "Coinbase"),
            Exchange(id: "Binance", name: "Binance", displayName: "Binance"),
            Exchange(id: "Kraken", name: "Kraken", displayName: "Kraken")
        ]
    }
    
    private func formatLargeNumber(_ number: Double) -> String {
        if number >= 1_000_000_000_000 {
            return String(format: "%.1fT", number / 1_000_000_000_000)
        } else if number >= 1_000_000_000 {
            return String(format: "%.1fB", number / 1_000_000_000)
        } else if number >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", number / 1_000)
        } else {
            return String(format: "%.0f", number)
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: result.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Text(result.symbol.prefix(1))
                            .font(.caption)
                            .fontWeight(.bold)
                    }
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(result.symbol)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let description = result.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let price = result.price {
                    Text(price.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if let change = result.change24h {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .foregroundColor(change >= 0 ? .green : .red)
                        
                        Text("\(String(format: "%.2f", change))%")
                            .font(.caption)
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
                
                if let rank = result.rank {
                    Text("#\(rank)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(16)
        }
    }
}


// MARK: - Custom Range Slider

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - 40
            let lowerPercent = (range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
            let upperPercent = (range.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
            
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                    .cornerRadius(2)
                    .offset(x: 20)
                
                // Active range
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: trackWidth * (upperPercent - lowerPercent), height: 4)
                    .cornerRadius(2)
                    .offset(x: 20 + trackWidth * lowerPercent)
                
                // Lower thumb
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 20, height: 20)
                    .offset(x: 10 + trackWidth * lowerPercent)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPercent = max(0, min(upperPercent, value.location.x / trackWidth))
                                let newValue = bounds.lowerBound + newPercent * (bounds.upperBound - bounds.lowerBound)
                                let steppedValue = round(newValue / step) * step
                                range = steppedValue...range.upperBound
                            }
                    )
                
                // Upper thumb
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 20, height: 20)
                    .offset(x: 10 + trackWidth * upperPercent)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPercent = max(lowerPercent, min(1, value.location.x / trackWidth))
                                let newValue = bounds.lowerBound + newPercent * (bounds.upperBound - bounds.lowerBound)
                                let steppedValue = round(newValue / step) * step
                                range = range.lowerBound...steppedValue
                            }
                    )
            }
        }
        .frame(height: 40)
    }
}

#Preview {
    AdvancedSearchView()
        .environment(AdvancedSearchService.shared)
}