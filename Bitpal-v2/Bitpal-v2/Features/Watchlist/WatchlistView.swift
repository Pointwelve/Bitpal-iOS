//
//  WatchlistView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CurrencyPair.sortOrder) private var currencyPairs: [CurrencyPair]
    @State private var watchlistViewModel = WatchlistViewModel()
    @State private var showingAddCurrency = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if currencyPairs.isEmpty {
                    EmptyWatchlistView {
                        showingAddCurrency = true
                    }
                } else {
                    watchlistContent
                }
            }
            .navigationTitle("Watchlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCurrency = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCurrency) {
                AddCurrencyView()
            }
            .task {
                watchlistViewModel.setModelContext(modelContext)
                // Only start price streaming if not already started by AppCoordinator
                await watchlistViewModel.startPriceStreamingIfNeeded(for: currencyPairs)
            }
            .onChange(of: currencyPairs.count) { oldCount, newCount in
                // Handle newly added currency pairs
                if newCount > oldCount {
                    print("🆕 WatchlistView: Detected new currency pairs (\(oldCount) → \(newCount))")
                    Task {
                        // Give a small delay to ensure SwiftData changes are fully processed
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        await watchlistViewModel.startPriceStreamingIfNeeded(for: currencyPairs)
                    }
                }
            }
            .refreshable {
                await refreshPrices()
            }
        }
    }
    
    private var watchlistContent: some View {
        List {
            ForEach(currencyPairs) { pair in
                NavigationLink(destination: CurrencyDetailView(currencyPair: pair)) {
                    WatchlistRowView(currencyPair: pair)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deletePair(pair)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: movePairs)
        }
        .listStyle(.plain)
    }
    
    private func refreshPrices() async {
        isRefreshing = true
        await watchlistViewModel.refreshPrices(for: currencyPairs)
        isRefreshing = false
    }
    
    private func deletePair(_ pair: CurrencyPair) {
        withAnimation {
            modelContext.delete(pair)
            try? modelContext.save()
        }
    }
    
    private func movePairs(from source: IndexSet, to destination: Int) {
        var pairs = currencyPairs
        pairs.move(fromOffsets: source, toOffset: destination)
        
        for (index, pair) in pairs.enumerated() {
            pair.sortOrder = index
        }
        
        try? modelContext.save()
    }
}

struct WatchlistRowView: View {
    let currencyPair: CurrencyPair
    @Environment(PriceStreamService.self) private var priceStreamService
    @State private var animatePrice = false
    
    private var streamPrice: StreamPrice? {
        priceStreamService.prices[currencyPair.primaryKey]
    }
    
    private var currentPrice: Double {
        streamPrice?.price ?? currencyPair.currentPrice
    }
    
    private var currentPriceChange: Double {
        streamPrice?.priceChange24h ?? currencyPair.priceChange24h
    }
    
    private var currentPriceChangePercent: Double {
        streamPrice?.priceChangePercent24h ?? currencyPair.priceChangePercent24h
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Currency Icon
            CurrencyIcon(currency: currencyPair.baseCurrency, size: 40)
            
            // Currency Info
            VStack(alignment: .leading, spacing: 4) {
                Text(currencyPair.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let exchange = currencyPair.exchange {
                    Text(exchange.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Price Info
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatPrice(currentPrice))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .scaleEffect(animatePrice ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animatePrice)
                
                PriceChangeView(
                    change: currentPriceChange,
                    changePercent: currentPriceChangePercent
                )
            }
        }
        .padding(.vertical, 4)
        .onChange(of: streamPrice?.price) { oldValue, newValue in
            if oldValue != newValue {
                withAnimation {
                    animatePrice = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animatePrice = false
                }
            }
        }
        .onChange(of: streamPrice?.priceChangePercent24h) { oldValue, newValue in
            if oldValue != newValue && newValue != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    animatePrice = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animatePrice = false
                }
            }
        }
        .onAppear {
            // Check if this currency pair needs price subscription
            if currentPrice == 0.0 {
                print("⚠️ WatchlistRowView: Currency pair \(currencyPair.displayName) has no price, triggering subscription")
                Task {
                    // Small delay to ensure UI is ready
                    try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                    
                    // Subscribe to price streaming
                    await priceStreamService.subscribe(to: currencyPair)
                    
                    // Also try to fetch latest price
                    do {
                        try await priceStreamService.fetchLatestPrices(for: [currencyPair])
                        print("✅ WatchlistRowView: Fetched price for \(currencyPair.displayName)")
                    } catch {
                        print("⚠️ WatchlistRowView: Failed to fetch price for \(currencyPair.displayName): \(error)")
                    }
                }
            }
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "$%.0f", price)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }
}

struct PriceChangeView: View {
    let change: Double
    let changePercent: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                .font(.caption2)
            
            Text("\(changePercent >= 0 ? "+" : "")\(String(format: "%.2f", changePercent))%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(isPositive ? .green : .red)
    }
    
    private var isPositive: Bool {
        change >= 0
    }
}


struct EmptyWatchlistView: View {
    let onAddCurrency: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Currencies")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add cryptocurrencies to start tracking prices")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Currency") {
                onAddCurrency()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}