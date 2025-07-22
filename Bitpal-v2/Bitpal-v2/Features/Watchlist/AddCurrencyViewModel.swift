//
//  AddCurrencyViewModel.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AddCurrencyViewModel {
    private(set) var availableCurrencies: [AvailableCurrency] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private var modelContext: ModelContext?
    private let apiClient = APIClient.shared
    
    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }
    
    func clearDuplicatesAndResetDatabase() {
        guard let context = modelContext else { return }
        
        do {
            // Get all currency pairs
            let allPairs = try context.fetch(FetchDescriptor<CurrencyPair>())
            var seenIds: Set<String> = []
            var duplicatesToDelete: [CurrencyPair] = []
            
            // Find duplicates
            for pair in allPairs {
                if seenIds.contains(pair.id) {
                    duplicatesToDelete.append(pair)
                } else {
                    seenIds.insert(pair.id)
                }
            }
            
            // Delete duplicates
            for duplicate in duplicatesToDelete {
                context.delete(duplicate)
            }
            
            try context.save()
            print("🧹 Cleaned up \(duplicatesToDelete.count) duplicate currency pairs")
            
        } catch {
            print("❌ Error cleaning duplicates: \(error)")
        }
    }
    
    func loadAvailableCurrencies() async {
        isLoading = true
        errorMessage = nil
        
        // For now, use a predefined list of popular currencies
        // In a real app, you'd fetch from the API
        availableCurrencies = [
            AvailableCurrency(id: "btc", name: "Bitcoin", symbol: "BTC", displaySymbol: "₿"),
            AvailableCurrency(id: "eth", name: "Ethereum", symbol: "ETH", displaySymbol: "Ξ"),
            AvailableCurrency(id: "ada", name: "Cardano", symbol: "ADA"),
            AvailableCurrency(id: "dot", name: "Polkadot", symbol: "DOT"),
            AvailableCurrency(id: "ltc", name: "Litecoin", symbol: "LTC"),
            AvailableCurrency(id: "link", name: "Chainlink", symbol: "LINK"),
            AvailableCurrency(id: "xrp", name: "XRP", symbol: "XRP"),
            AvailableCurrency(id: "bch", name: "Bitcoin Cash", symbol: "BCH"),
            AvailableCurrency(id: "xlm", name: "Stellar", symbol: "XLM"),
            AvailableCurrency(id: "uni", name: "Uniswap", symbol: "UNI"),
            AvailableCurrency(id: "doge", name: "Dogecoin", symbol: "DOGE"),
            AvailableCurrency(id: "matic", name: "Polygon", symbol: "MATIC"),
            AvailableCurrency(id: "sol", name: "Solana", symbol: "SOL"),
            AvailableCurrency(id: "avax", name: "Avalanche", symbol: "AVAX"),
            AvailableCurrency(id: "atom", name: "Cosmos", symbol: "ATOM")
        ]
        
        isLoading = false
    }
    
    func addCurrencyPair(_ availableCurrency: AvailableCurrency) {
        guard let context = modelContext else { 
            print("❌ AddCurrencyViewModel: No model context available")
            return 
        }
        
        print("🔄 Adding currency pair: \(availableCurrency.symbol)/USD")
        
        do {
            // Check if currency already exists
            let allCurrencies = try context.fetch(FetchDescriptor<Currency>())
            let existingCurrencies = allCurrencies.filter { $0.symbol == availableCurrency.symbol }
            let baseCurrency: Currency
            
            if let existing = existingCurrencies.first {
                baseCurrency = existing
            } else {
                baseCurrency = Currency(
                    id: availableCurrency.id,
                    name: availableCurrency.name,
                    symbol: availableCurrency.symbol,
                    displaySymbol: availableCurrency.displaySymbol ?? availableCurrency.symbol
                )
                context.insert(baseCurrency)
            }
            
            // Get or create USD quote currency
            let allUsdCurrencies = try context.fetch(FetchDescriptor<Currency>())
            let usdCurrencies = allUsdCurrencies.filter { $0.symbol == "USD" }
            let quoteCurrency: Currency
            
            if let existingUSD = usdCurrencies.first {
                quoteCurrency = existingUSD
            } else {
                // Create a new USD Currency object to avoid context conflicts
                quoteCurrency = Currency(
                    id: "usd",
                    name: "US Dollar",
                    symbol: "USD",
                    displaySymbol: "$"
                )
                context.insert(quoteCurrency)
            }
            
            // Check if pair already exists using the generated ID (without exchange)
            let expectedPairId = "\(availableCurrency.symbol.uppercased())-USD"
            let pairDescriptor = FetchDescriptor<CurrencyPair>(
                predicate: #Predicate { $0.id == expectedPairId }
            )
            let existingPairs = try context.fetch(pairDescriptor)
            
            print("🔍 Looking for existing pair with ID: \(expectedPairId)")
            print("🔍 Found \(existingPairs.count) existing pairs")
            
            if existingPairs.isEmpty {
                print("✅ Creating new currency pair...")
                // Get current max sort order
                let allPairsDescriptor = FetchDescriptor<CurrencyPair>(
                    sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
                )
                let allPairs = try context.fetch(allPairsDescriptor)
                let nextSortOrder = (allPairs.first?.sortOrder ?? -1) + 1
                
                // Create the currency pair without exchange
                let currencyPair = CurrencyPair(
                    baseCurrency: baseCurrency,
                    quoteCurrency: quoteCurrency,
                    sortOrder: nextSortOrder
                )
                
                print("✅ Created currency pair with ID: \(currencyPair.id)")
                
                // Double-check no duplicate exists before insertion
                let finalCheckDescriptor = FetchDescriptor<CurrencyPair>(
                    predicate: #Predicate { $0.id == currencyPair.id }
                )
                let duplicateCheck = try context.fetch(finalCheckDescriptor)
                
                if duplicateCheck.isEmpty {
                    context.insert(currencyPair)
                    print("✅ Currency pair inserted with sort order: \(nextSortOrder)")
                } else {
                    print("⚠️ Duplicate currency pair detected during insertion, skipping")
                }
            } else {
                print("⚠️ Currency pair already exists, skipping")
            }
            
            try context.save()
            print("✅ Context saved successfully")
            
        } catch {
            errorMessage = "Failed to add currency: \(error.localizedDescription)"
            print("❌ AddCurrencyViewModel Error: \(error)")
        }
    }
}