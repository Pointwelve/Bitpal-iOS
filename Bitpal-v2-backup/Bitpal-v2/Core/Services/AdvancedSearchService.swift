//
//  AdvancedSearchService.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftData
import Foundation
import Combine
import Observation

@MainActor
@Observable
final class AdvancedSearchService: ReactiveService {
    static let shared = AdvancedSearchService()
    
    private(set) var searchHistory: [SearchQuery] = []
    private(set) var popularSearches: [String] = []
    private(set) var searchSuggestions: [SearchSuggestion] = []
    private(set) var isLoading = false
    
    private var modelContext: ModelContext?
    private let apiClient = APIClient.shared
    private let searchCache = ReactiveCacheManager<String, [SearchResult]>()
    private let suggestionCache = ReactiveCacheManager<String, [SearchSuggestion]>()
    
    override init() {
        super.init()
        loadPopularSearches()
    }
    
    func setModelContext(_ context: ModelContext) {
        modelContext = context
        Task {
            await loadSearchHistory()
        }
    }
    
    // MARK: - Advanced Search
    
    func performAdvancedSearch(parameters: AdvancedSearchParameters) async throws -> [SearchResult] {
        let cacheKey = parameters.cacheKey
        
        // Check cache first
        if let cached = await searchCache.getValue(forKey: cacheKey).singleOutput() {
            return cached ?? []
        }
        
        setProcessing(true)
        isLoading = true
        
        defer { 
            setProcessing(false)
            isLoading = false
        }
        
        do {
            var results: [SearchResult] = []
            
            // Search different categories based on parameters
            switch parameters.category {
            case .all:
                let currencies = try await searchCurrencies(parameters)
                let exchanges = try await searchExchanges(parameters)
                let news = try await searchNews(parameters)
                results = currencies + exchanges + news
                
            case .currencies:
                results = try await searchCurrencies(parameters)
                
            case .exchanges:
                results = try await searchExchanges(parameters)
                
            case .news:
                results = try await searchNews(parameters)
                
            case .defi:
                results = try await searchDeFiProjects(parameters)
                
            case .nft:
                results = try await searchNFTCollections(parameters)
            }
            
            // Apply filters and sorting
            results = applyFilters(to: results, parameters: parameters)
            results = applySorting(to: results, parameters: parameters)
            
            // Cache results
            searchCache.setValue(results, forKey: cacheKey, expirationInterval: 300)
            
            // Save search query to history
            await saveSearchQuery(parameters)
            
            return results
            
        } catch {
            sendError(error)
            throw error
        }
    }
    
    // MARK: - Search Suggestions
    
    func getSearchSuggestions(for query: String) async throws -> [SearchSuggestion] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let cacheKey = "suggestions_\(query.lowercased())"
        
        // Check cache first
        if let cached = await suggestionCache.getValue(forKey: cacheKey).singleOutput() {
            return cached ?? []
        }
        
        do {
            var suggestions: [SearchSuggestion] = []
            
            // Currency suggestions
            let currencyResponse: CurrencySearchResponse = try await apiClient.request(
                CryptoAPIEndpoint.searchCurrencies(query: query, limit: 10)
            )
            
            suggestions += currencyResponse.results.map { result in
                SearchSuggestion(
                    id: result.id,
                    text: result.name,
                    subtitle: result.symbol,
                    type: .currency,
                    imageUrl: result.logo
                )
            }
            
            // Exchange suggestions
            let exchangeResponse: ExchangeSearchResponse = try await apiClient.request(
                CryptoAPIEndpoint.searchExchanges(query: query, limit: 5)
            )
            
            suggestions += exchangeResponse.results.map { result in
                SearchSuggestion(
                    id: result.id,
                    text: result.name,
                    subtitle: result.description,
                    type: .exchange,
                    imageUrl: result.logo
                )
            }
            
            // Add search history matches
            let historyMatches = searchHistory
                .filter { $0.query.localizedCaseInsensitiveContains(query) }
                .prefix(3)
                .map { history in
                    SearchSuggestion(
                        id: history.id,
                        text: history.query,
                        subtitle: "Recent search",
                        type: .history,
                        imageUrl: nil
                    )
                }
            
            suggestions += historyMatches
            
            // Cache suggestions
            suggestionCache.setValue(suggestions, forKey: cacheKey, expirationInterval: 600)
            
            return suggestions
            
        } catch {
            sendError(error)
            throw error
        }
    }
    
    // MARK: - Search History
    
    func clearSearchHistory() async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<SearchQuery>()
            let queries = try context.fetch(descriptor)
            
            for query in queries {
                context.delete(query)
            }
            
            try context.save()
            searchHistory = []
            
        } catch {
            sendError(error)
        }
    }
    
    func removeSearchQuery(_ query: SearchQuery) async {
        guard let context = modelContext else { return }
        
        context.delete(query)
        try? context.save()
        
        await loadSearchHistory()
    }
    
    // MARK: - Private Implementation
    
    private func searchCurrencies(_ parameters: AdvancedSearchParameters) async throws -> [SearchResult] {
        let response: CurrencySearchResponse = try await apiClient.request(
            CryptoAPIEndpoint.searchCurrencies(query: parameters.query, limit: 50)
        )
        
        return response.results.map { result in
            SearchResult(
                id: result.id,
                name: result.name,
                symbol: result.symbol,
                type: .currency,
                description: result.description,
                imageUrl: result.logo,
                price: result.price,
                change24h: result.percentChange24h,
                marketCap: result.marketCap,
                volume24h: result.volume24h,
                rank: result.rank
            )
        }
    }
    
    private func searchExchanges(_ parameters: AdvancedSearchParameters) async throws -> [SearchResult] {
        let response: ExchangeSearchResponse = try await apiClient.request(
            CryptoAPIEndpoint.searchExchanges(query: parameters.query, limit: 20)
        )
        
        return response.results.map { result in
            SearchResult(
                id: result.id,
                name: result.name,
                symbol: result.slug,
                type: .exchange,
                description: result.description,
                imageUrl: result.logo,
                price: nil,
                change24h: nil,
                marketCap: nil,
                volume24h: result.volume24h,
                rank: nil
            )
        }
    }
    
    private func searchNews(_ parameters: AdvancedSearchParameters) async throws -> [SearchResult] {
        let response: NewsResponse = try await apiClient.request(
            CryptoAPIEndpoint.news(categories: nil, excludeCategories: nil, sources: nil, lang: "EN")
        )
        
        let filteredNews = response.data.filter { news in
            news.title.localizedCaseInsensitiveContains(parameters.query) ||
            news.body.localizedCaseInsensitiveContains(parameters.query) ||
            news.tags.localizedCaseInsensitiveContains(parameters.query)
        }
        
        return Array(filteredNews.prefix(10)).map { news in
            SearchResult(
                id: news.id,
                name: news.title,
                symbol: news.source,
                type: .news,
                description: String(news.body.prefix(150)),
                imageUrl: news.imageUrl,
                price: nil,
                change24h: nil,
                marketCap: nil,
                volume24h: nil,
                rank: nil
            )
        }
    }
    
    private func searchDeFiProjects(_ parameters: AdvancedSearchParameters) async throws -> [SearchResult] {
        // Implement DeFi-specific search
        let response: CurrencySearchResponse = try await apiClient.request(
            CryptoAPIEndpoint.searchCurrencies(query: "\(parameters.query) DeFi", limit: 20)
        )
        
        return response.results.compactMap { result in
            // Filter for DeFi-related tokens
            guard result.description?.localizedCaseInsensitiveContains("defi") == true ||
                  result.description?.localizedCaseInsensitiveContains("decentralized") == true ||
                  result.name.localizedCaseInsensitiveContains("defi") else {
                return nil
            }
            
            return SearchResult(
                id: result.id,
                name: result.name,
                symbol: result.symbol,
                type: .defi,
                description: result.description,
                imageUrl: result.logo,
                price: result.price,
                change24h: result.percentChange24h,
                marketCap: result.marketCap,
                volume24h: result.volume24h,
                rank: result.rank
            )
        }
    }
    
    private func searchNFTCollections(_ parameters: AdvancedSearchParameters) async throws -> [SearchResult] {
        // Implement NFT-specific search
        let response: CurrencySearchResponse = try await apiClient.request(
            CryptoAPIEndpoint.searchCurrencies(query: "\(parameters.query) NFT", limit: 20)
        )
        
        return response.results.compactMap { result in
            // Filter for NFT-related tokens
            guard result.description?.localizedCaseInsensitiveContains("nft") == true ||
                  result.description?.localizedCaseInsensitiveContains("non-fungible") == true ||
                  result.name.localizedCaseInsensitiveContains("nft") else {
                return nil
            }
            
            return SearchResult(
                id: result.id,
                name: result.name,
                symbol: result.symbol,
                type: .nft,
                description: result.description,
                imageUrl: result.logo,
                price: result.price,
                change24h: result.percentChange24h,
                marketCap: result.marketCap,
                volume24h: result.volume24h,
                rank: result.rank
            )
        }
    }
    
    private func applyFilters(to results: [SearchResult], parameters: AdvancedSearchParameters) -> [SearchResult] {
        return results.filter { result in
            // Price filter
            if let price = result.price {
                guard parameters.priceRange.contains(price) else { return false }
            }
            
            // Market cap filter
            if let marketCap = result.marketCap {
                guard parameters.marketCapRange.contains(marketCap) else { return false }
            }
            
            // Volume filter
            if let volume = result.volume24h {
                guard parameters.volumeRange.contains(volume) else { return false }
            }
            
            // Change filter
            if let change = result.change24h {
                guard parameters.changeRange.contains(change) else { return false }
            }
            
            // Rank filter
            if let rank = result.rank {
                guard parameters.rankRange.contains(rank) else { return false }
            }
            
            // Additional filters can be applied here
            
            return true
        }
    }
    
    private func applySorting(to results: [SearchResult], parameters: AdvancedSearchParameters) -> [SearchResult] {
        let sorted = results.sorted { first, second in
            switch parameters.sortBy {
            case .relevance:
                // Simple relevance scoring based on name match
                let firstScore = calculateRelevanceScore(first, query: parameters.query)
                let secondScore = calculateRelevanceScore(second, query: parameters.query)
                return firstScore > secondScore
                
            case .price:
                let firstPrice = first.price ?? 0
                let secondPrice = second.price ?? 0
                return firstPrice > secondPrice
                
            case .marketCap:
                let firstCap = first.marketCap ?? 0
                let secondCap = second.marketCap ?? 0
                return firstCap > secondCap
                
            case .volume:
                let firstVolume = first.volume24h ?? 0
                let secondVolume = second.volume24h ?? 0
                return firstVolume > secondVolume
                
            case .change24h:
                let firstChange = first.change24h ?? 0
                let secondChange = second.change24h ?? 0
                return firstChange > secondChange
                
            case .name:
                return first.name < second.name
                
            case .rank:
                let firstRank = first.rank ?? Int.max
                let secondRank = second.rank ?? Int.max
                return firstRank < secondRank
            }
        }
        
        return parameters.sortOrder == .ascending ? sorted.reversed() : sorted
    }
    
    private func calculateRelevanceScore(_ result: SearchResult, query: String) -> Int {
        let lowercaseQuery = query.lowercased()
        let lowercaseName = result.name.lowercased()
        let lowercaseSymbol = result.symbol.lowercased()
        
        var score = 0
        
        // Exact matches get highest score
        if lowercaseName == lowercaseQuery || lowercaseSymbol == lowercaseQuery {
            score += 100
        }
        
        // Name starts with query
        if lowercaseName.hasPrefix(lowercaseQuery) {
            score += 50
        }
        
        // Symbol starts with query
        if lowercaseSymbol.hasPrefix(lowercaseQuery) {
            score += 40
        }
        
        // Name contains query
        if lowercaseName.contains(lowercaseQuery) {
            score += 20
        }
        
        // Symbol contains query
        if lowercaseSymbol.contains(lowercaseQuery) {
            score += 10
        }
        
        // Description contains query
        if let description = result.description?.lowercased(), description.contains(lowercaseQuery) {
            score += 5
        }
        
        return score
    }
    
    private func saveSearchQuery(_ parameters: AdvancedSearchParameters) async {
        guard let context = modelContext else { return }
        
        // Check if query already exists
        let queryString = parameters.query
        var descriptor = FetchDescriptor<SearchQuery>()
        descriptor.predicate = #Predicate<SearchQuery> { query in
            query.query == queryString
        }
        
        do {
            let existingQueries = try context.fetch(descriptor)
            
            if let existingQuery = existingQueries.first {
                existingQuery.timestamp = Date()
                existingQuery.searchCount += 1
            } else {
                let newQuery = SearchQuery(
                    query: parameters.query,
                    category: parameters.category.rawValue,
                    timestamp: Date(),
                    searchCount: 1
                )
                context.insert(newQuery)
            }
            
            try context.save()
            await loadSearchHistory()
            
        } catch {
            sendError(error)
        }
    }
    
    private func loadSearchHistory() async {
        guard let context = modelContext else { return }
        
        do {
            var descriptor = FetchDescriptor<SearchQuery>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = 50
            
            searchHistory = try context.fetch(descriptor)
            
        } catch {
            sendError(error)
        }
    }
    
    private func loadPopularSearches() {
        popularSearches = [
            "Bitcoin",
            "Ethereum", 
            "DeFi",
            "NFT",
            "Stablecoin",
            "Metaverse",
            "Layer 2",
            "Web3",
            "GameFi",
            "Meme coin"
        ]
    }
}

// MARK: - Supporting Models

struct AdvancedSearchParameters {
    let query: String
    let category: SearchCategory
    let sortBy: SortOption
    let sortOrder: SortOrder
    let priceRange: ClosedRange<Double>
    let marketCapRange: ClosedRange<Double>
    let volumeRange: ClosedRange<Double>
    let changeRange: ClosedRange<Double>
    let selectedExchanges: Set<String>
    let showOnlyFavorites: Bool
    let showOnlyWithAlerts: Bool
    let rankRange: ClosedRange<Int>
    
    var cacheKey: String {
        let rangeString = "\(priceRange.lowerBound)-\(priceRange.upperBound)"
        let exchangeString = selectedExchanges.sorted().joined(separator: ",")
        let favoritesString = showOnlyFavorites ? "fav" : ""
        let alertsString = showOnlyWithAlerts ? "alerts" : ""
        
        return "\(query)_\(category.rawValue)_\(sortBy.rawValue)_\(sortOrder.rawValue)_\(rangeString)_\(exchangeString)_\(favoritesString)_\(alertsString)"
    }
}

enum SearchCategory: String, CaseIterable {
    case all = "all"
    case currencies = "currencies"
    case exchanges = "exchanges"
    case news = "news"
    case defi = "defi"
    case nft = "nft"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .currencies: return "Currencies"
        case .exchanges: return "Exchanges"
        case .news: return "News"
        case .defi: return "DeFi"
        case .nft: return "NFT"
        }
    }
}

enum SortOption: String, CaseIterable {
    case relevance = "relevance"
    case price = "price"
    case marketCap = "market_cap"
    case volume = "volume"
    case change24h = "change_24h"
    case name = "name"
    case rank = "rank"
    
    var displayName: String {
        switch self {
        case .relevance: return "Relevance"
        case .price: return "Price"
        case .marketCap: return "Market Cap"
        case .volume: return "Volume"
        case .change24h: return "24h Change"
        case .name: return "Name"
        case .rank: return "Rank"
        }
    }
    
    var systemImage: String {
        switch self {
        case .relevance: return "star.fill"
        case .price: return "dollarsign.circle"
        case .marketCap: return "chart.pie"
        case .volume: return "chart.bar"
        case .change24h: return "arrow.up.arrow.down"
        case .name: return "textformat.abc"
        case .rank: return "number"
        }
    }
}

enum SortOrder: String, CaseIterable {
    case ascending = "asc"
    case descending = "desc"
    
    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
    
    var systemImage: String {
        switch self {
        case .ascending: return "arrow.up"
        case .descending: return "arrow.down"
        }
    }
}

struct SearchResult: Identifiable, Codable {
    let id: String
    let name: String
    let symbol: String
    let type: SearchResultType
    let description: String?
    let imageUrl: String?
    let price: Double?
    let change24h: Double?
    let marketCap: Double?
    let volume24h: Double?
    let rank: Int?
}

enum SearchResultType: String, Codable {
    case currency = "currency"
    case exchange = "exchange"
    case news = "news"
    case defi = "defi"
    case nft = "nft"
}

struct SearchSuggestion: Identifiable, Codable {
    let id: String
    let text: String
    let subtitle: String?
    let type: SuggestionType
    let imageUrl: String?
}

enum SuggestionType: String, Codable {
    case currency = "currency"
    case exchange = "exchange"
    case history = "history"
    case popular = "popular"
}

@Model
final class SearchQuery {
    var id: String = UUID().uuidString
    var query: String
    var category: String
    var timestamp: Date
    var searchCount: Int
    
    init(query: String, category: String, timestamp: Date, searchCount: Int = 1) {
        self.query = query
        self.category = category
        self.timestamp = timestamp
        self.searchCount = searchCount
    }
}