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
    
    func addCurrencyPair(_ availableCurrency: AvailableCurrency, exchange: Exchange? = nil) {
        guard let context = modelContext else { return }
        
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
                    displaySymbol: availableCurrency.displaySymbol
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
                quoteCurrency = Currency.usd()
                context.insert(quoteCurrency)
            }
            
            // Get or create exchange
            let targetExchange: Exchange
            if let providedExchange = exchange {
                // Check if exchange already exists
                let allExchanges = try context.fetch(FetchDescriptor<Exchange>())
                let existingExchanges = allExchanges.filter { $0.id == providedExchange.id }
                
                if let existing = existingExchanges.first {
                    targetExchange = existing
                } else {
                    targetExchange = Exchange(
                        id: providedExchange.id,
                        name: providedExchange.name,
                        displayName: providedExchange.displayName
                    )
                    context.insert(targetExchange)
                }
            } else {
                // Default to CoinDesk
                let allExchanges = try context.fetch(FetchDescriptor<Exchange>())
                let exchanges = allExchanges.filter { $0.id == "COINDESK" }
                
                if let existingExchange = exchanges.first {
                    targetExchange = existingExchange
                } else {
                    targetExchange = Exchange(id: "COINDESK", name: "CoinDesk", displayName: "CoinDesk")
                    context.insert(targetExchange)
                }
            }
            
            // Check if pair already exists
            let allPairs = try context.fetch(FetchDescriptor<CurrencyPair>())
            let existingPairs = allPairs.filter { pair in
                pair.baseCurrency?.symbol == availableCurrency.symbol &&
                pair.quoteCurrency?.symbol == "USD" &&
                pair.exchange?.id == targetExchange.id
            }
            
            if existingPairs.isEmpty {
                // Get current max sort order
                let allPairsDescriptor = FetchDescriptor<CurrencyPair>(
                    sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
                )
                let allPairs = try context.fetch(allPairsDescriptor)
                let nextSortOrder = (allPairs.first?.sortOrder ?? -1) + 1
                
                let currencyPair = CurrencyPair(
                    baseCurrency: baseCurrency,
                    quoteCurrency: quoteCurrency,
                    exchange: targetExchange,
                    sortOrder: nextSortOrder
                )
                
                context.insert(currencyPair)
            }
            
            try context.save()
            
        } catch {
            errorMessage = "Failed to add currency: \(error.localizedDescription)"
        }
    }
}