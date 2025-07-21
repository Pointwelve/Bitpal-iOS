//
//  CurrencySearchService.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class CurrencySearchService {
    static let shared = CurrencySearchService()
    
    private(set) var availableCurrencies: [AvailableCurrency] = []
    private(set) var availableExchanges: [Exchange] = []
    private(set) var searchResults: [AvailableCurrency] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private let apiClient = APIClient.shared
    private var allCurrencies: [AvailableCurrency] = []
    private var searchTask: Task<Void, Never>?
    
    private init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        await loadAvailableCurrencies()
        await loadAvailableExchanges()
    }
    
    private func loadAvailableCurrencies() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try to load from API first
            let response: CurrencyListResponse = try await apiClient.request(CryptoAPIEndpoint.coinList)
            allCurrencies = response.data.compactMap { currencyData in
                AvailableCurrency(
                    id: currencyData.symbol.lowercased(),
                    name: currencyData.coinName,
                    symbol: currencyData.symbol,
                    displaySymbol: currencyData.displaySymbol,
                    imageUrl: currencyData.imageUrl,
                    isActive: currencyData.isActive
                )
            }
            .filter { $0.isActive }
            .sorted { $0.name < $1.name }
            
            availableCurrencies = Array(allCurrencies.prefix(100)) // Show top 100 initially
            searchResults = availableCurrencies
            
        } catch {
            // Fallback to hardcoded popular currencies
            allCurrencies = getPopularCurrencies()
            availableCurrencies = allCurrencies
            searchResults = availableCurrencies
            
            errorMessage = "Using offline currency list: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadAvailableExchanges() async {
        do {
            let response: ExchangeListResponse = try await apiClient.request(CryptoAPIEndpoint.exchangeList)
            availableExchanges = response.data.map { exchangeData in
                Exchange(
                    id: exchangeData.id,
                    name: exchangeData.name,
                    displayName: exchangeData.displayName ?? exchangeData.name,
                    isActive: exchangeData.isActive
                )
            }
            .filter { $0.isActive }
            .sorted { $0.displayName < $1.displayName }
            
        } catch {
            // Fallback to popular exchanges
            availableExchanges = getPopularExchanges()
        }
    }
    
    // MARK: - Search
    
    func searchCurrencies(_ query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = Array(availableCurrencies.prefix(100))
            return
        }
        
        searchTask = Task {
            // Add small delay for better UX
            try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
            
            guard !Task.isCancelled else { return }
            
            let lowercaseQuery = query.lowercased()
            let filtered = allCurrencies.filter { currency in
                currency.name.lowercased().contains(lowercaseQuery) ||
                currency.symbol.lowercased().contains(lowercaseQuery) ||
                currency.id.lowercased().contains(lowercaseQuery)
            }
            
            // Sort by relevance
            let sorted = filtered.sorted { first, second in
                let firstScore = calculateRelevanceScore(currency: first, query: lowercaseQuery)
                let secondScore = calculateRelevanceScore(currency: second, query: lowercaseQuery)
                return firstScore > secondScore
            }
            
            guard !Task.isCancelled else { return }
            
            searchResults = Array(sorted.prefix(50)) // Limit results
        }
    }
    
    private func calculateRelevanceScore(currency: AvailableCurrency, query: String) -> Int {
        var score = 0
        
        // Exact symbol match gets highest score
        if currency.symbol.lowercased() == query {
            score += 100
        } else if currency.symbol.lowercased().hasPrefix(query) {
            score += 80
        } else if currency.symbol.lowercased().contains(query) {
            score += 40
        }
        
        // Name matches
        if currency.name.lowercased() == query {
            score += 90
        } else if currency.name.lowercased().hasPrefix(query) {
            score += 70
        } else if currency.name.lowercased().contains(query) {
            score += 30
        }
        
        // ID matches
        if currency.id.lowercased() == query {
            score += 85
        } else if currency.id.lowercased().hasPrefix(query) {
            score += 60
        } else if currency.id.lowercased().contains(query) {
            score += 20
        }
        
        return score
    }
    
    // MARK: - Exchange Validation
    
    func getAvailableExchanges(for baseCurrency: String, quoteCurrency: String = "USD") async -> [Exchange] {
        // In a real app, you'd check which exchanges actually support this trading pair
        // For now, return all active exchanges
        return availableExchanges
    }
    
    func validateCurrencyPair(base: String, quote: String, exchange: String) async -> Bool {
        do {
            // Check if the trading pair exists on the specified exchange
            let request = CurrencyPairValidationRequest(
                baseCurrency: base,
                quoteCurrency: quote,
                exchange: exchange
            )
            let response: CurrencyPairValidationResponse = try await apiClient.request(CryptoAPIEndpoint.validateCurrencyPair(request))
            return response.isValid
        } catch {
            // If validation fails, assume it's valid for popular pairs
            return isPopularCurrency(base) && isPopularCurrency(quote)
        }
    }
    
    // MARK: - Currency Categories
    
    func getTopCurrencies() -> [AvailableCurrency] {
        return getPopularCurrencies()
    }
    
    func getTrendingCurrencies() async -> [AvailableCurrency] {
        do {
            let response: TrendingCurrenciesResponse = try await apiClient.request(CryptoAPIEndpoint.trendingCoins)
            return response.coins.compactMap { coinData in
                allCurrencies.first { $0.symbol == coinData.symbol }
            }
        } catch {
            // Fallback to top currencies
            return Array(getPopularCurrencies().prefix(10))
        }
    }
    
    func getRecentlyAdded() -> [AvailableCurrency] {
        // In a real app, you'd track recently added currencies
        return Array(availableCurrencies.suffix(10))
    }
    
    // MARK: - Fallback Data
    
    private func getPopularCurrencies() -> [AvailableCurrency] {
        return [
            AvailableCurrency(id: "btc", name: "Bitcoin", symbol: "BTC", displaySymbol: "₿"),
            AvailableCurrency(id: "eth", name: "Ethereum", symbol: "ETH", displaySymbol: "Ξ"),
            AvailableCurrency(id: "usdt", name: "Tether", symbol: "USDT", displaySymbol: "₮"),
            AvailableCurrency(id: "bnb", name: "BNB", symbol: "BNB"),
            AvailableCurrency(id: "sol", name: "Solana", symbol: "SOL"),
            AvailableCurrency(id: "usdc", name: "USD Coin", symbol: "USDC"),
            AvailableCurrency(id: "xrp", name: "XRP", symbol: "XRP"),
            AvailableCurrency(id: "doge", name: "Dogecoin", symbol: "DOGE", displaySymbol: "Ð"),
            AvailableCurrency(id: "ton", name: "Toncoin", symbol: "TON"),
            AvailableCurrency(id: "ada", name: "Cardano", symbol: "ADA"),
            AvailableCurrency(id: "shib", name: "Shiba Inu", symbol: "SHIB"),
            AvailableCurrency(id: "avax", name: "Avalanche", symbol: "AVAX"),
            AvailableCurrency(id: "dot", name: "Polkadot", symbol: "DOT"),
            AvailableCurrency(id: "link", name: "Chainlink", symbol: "LINK"),
            AvailableCurrency(id: "bch", name: "Bitcoin Cash", symbol: "BCH"),
            AvailableCurrency(id: "ltc", name: "Litecoin", symbol: "LTC"),
            AvailableCurrency(id: "uni", name: "Uniswap", symbol: "UNI"),
            AvailableCurrency(id: "matic", name: "Polygon", symbol: "MATIC"),
            AvailableCurrency(id: "etc", name: "Ethereum Classic", symbol: "ETC"),
            AvailableCurrency(id: "atom", name: "Cosmos", symbol: "ATOM"),
            AvailableCurrency(id: "xlm", name: "Stellar", symbol: "XLM"),
            AvailableCurrency(id: "fil", name: "Filecoin", symbol: "FIL"),
            AvailableCurrency(id: "hbar", name: "Hedera", symbol: "HBAR"),
            AvailableCurrency(id: "vet", name: "VeChain", symbol: "VET"),
            AvailableCurrency(id: "algo", name: "Algorand", symbol: "ALGO")
        ]
    }
    
    private func getPopularExchanges() -> [Exchange] {
        return [
            Exchange(id: "COINDESK", name: "CoinDesk", displayName: "CoinDesk"),
            Exchange(id: "Binance", name: "Binance", displayName: "Binance"),
            Exchange(id: "Coinbase", name: "Coinbase Pro", displayName: "Coinbase Pro"),
            Exchange(id: "Kraken", name: "Kraken", displayName: "Kraken"),
            Exchange(id: "Bitfinex", name: "Bitfinex", displayName: "Bitfinex"),
            Exchange(id: "Bitstamp", name: "Bitstamp", displayName: "Bitstamp"),
            Exchange(id: "KuCoin", name: "KuCoin", displayName: "KuCoin"),
            Exchange(id: "OKX", name: "OKX", displayName: "OKX"),
            Exchange(id: "Gemini", name: "Gemini", displayName: "Gemini"),
            Exchange(id: "Huobi", name: "Huobi", displayName: "Huobi")
        ]
    }
    
    private func isPopularCurrency(_ symbol: String) -> Bool {
        let popularSymbols = ["BTC", "ETH", "USDT", "BNB", "SOL", "USDC", "XRP", "DOGE", "ADA", "AVAX", "DOT", "LINK", "LTC", "BCH", "UNI", "MATIC"]
        return popularSymbols.contains(symbol.uppercased())
    }
}

// MARK: - Data Models

struct AvailableCurrency: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let displaySymbol: String?
    let imageUrl: String?
    let isActive: Bool
    
    init(id: String, name: String, symbol: String, displaySymbol: String? = nil, imageUrl: String? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.displaySymbol = displaySymbol
        self.imageUrl = imageUrl
        self.isActive = isActive
    }
    
    var effectiveDisplaySymbol: String {
        displaySymbol ?? symbol
    }
}

// MARK: - API Models

struct CurrencyListResponse: Codable {
    let data: [CurrencyData]
}

struct CurrencyData: Codable {
    let id: String
    let symbol: String
    let name: String
    let displaySymbol: String?
    let imageUrl: String?
    let isActive: Bool
    
    var coinName: String { name }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case displaySymbol = "display_symbol"
        case imageUrl = "image_url"
        case isActive = "is_active"
    }
}

struct ExchangeListResponse: Codable {
    let data: [ExchangeData]
}

struct ExchangeData: Codable {
    let id: String
    let name: String
    let displayName: String?
    let isActive: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName = "display_name"
        case isActive = "is_active"
    }
}

struct CurrencyPairValidationRequest: Codable {
    let baseCurrency: String
    let quoteCurrency: String
    let exchange: String
}

struct CurrencyPairValidationResponse: Codable {
    let isValid: Bool
    let message: String?
}

struct TrendingCurrenciesResponse: Codable {
    let coins: [TrendingCoin]
}

struct TrendingCoin: Codable {
    let symbol: String
    let name: String
}