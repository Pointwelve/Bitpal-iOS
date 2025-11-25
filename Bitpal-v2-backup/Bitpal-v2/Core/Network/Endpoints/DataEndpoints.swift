//
//  DataEndpoints.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

enum DataEndpoints: APIEndpoint {
    case coinList
    case exchangeList
    case topCoins(limit: Int, currency: String)
    case trendingCoins
    case validateCurrencyPair(CurrencyPairValidationRequest)
    case topExchanges(currency: String)
    case socialStats(symbol: String)
    case miningStats(symbol: String)
    case news(categories: [String]?, excludeCategories: [String]?, sources: [String]?, lang: String?)
    
    var path: String {
        switch self {
        case .coinList:
            return "/v2/tb/currency/info"
        case .exchangeList:
            return "/v2/tb/exchange/info"
        case .topCoins:
            return "/v2/tb/currency/info"
        case .trendingCoins:
            return "/v2/tb/currency/trending"
        case .validateCurrencyPair:
            return "/v2/tb/currency/validate"
        case .topExchanges:
            return "/v2/tb/exchange/info"
        case .socialStats:
            return "/v2/tb/social/stats"
        case .miningStats:
            return "/v2/tb/mining/stats"
        case .news:
            return "/v2/tb/news"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .validateCurrencyPair:
            return .POST
        default:
            return .GET
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .topCoins(let limit, let currency):
            return [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "currency", value: currency)
            ]
            
        case .topExchanges(let currency):
            return [URLQueryItem(name: "currency", value: currency)]
            
        case .socialStats(let symbol), .miningStats(let symbol):
            return [URLQueryItem(name: "symbol", value: symbol)]
            
        case .news(let categories, let excludeCategories, let sources, let lang):
            var items: [URLQueryItem] = []
            if let categories = categories {
                items.append(URLQueryItem(name: "categories", value: categories.joined(separator: ",")))
            }
            if let excludeCategories = excludeCategories {
                items.append(URLQueryItem(name: "exclude_categories", value: excludeCategories.joined(separator: ",")))
            }
            if let sources = sources {
                items.append(URLQueryItem(name: "sources", value: sources.joined(separator: ",")))
            }
            if let lang = lang {
                items.append(URLQueryItem(name: "lang", value: lang))
            }
            return items.isEmpty ? nil : items
            
        default:
            return nil
        }
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var body: [String: Any]? {
        switch self {
        case .validateCurrencyPair(let request):
            // Convert to dictionary for the protocol
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
            return nil
        default:
            return nil
        }
    }
    
    func url(baseURL: URL, apiKey: String) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        
        var allQueryItems = queryItems ?? []
        
        if !apiKey.isEmpty {
            allQueryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        }
        
        components?.queryItems = allQueryItems.isEmpty ? nil : allQueryItems
        return components?.url
    }
}