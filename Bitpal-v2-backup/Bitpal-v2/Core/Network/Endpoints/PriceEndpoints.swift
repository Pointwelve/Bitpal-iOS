//
//  PriceEndpoints.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

enum PriceEndpoints: APIEndpoint {
    case priceMulti(symbols: [String], currencies: [String])
    case priceHistorical(symbol: String, currency: String, exchange: String?, period: APIChartPeriod, limit: Int)
    case priceStream(symbols: [String], currencies: [String], exchange: String?)
    case ohlcv(symbol: String, currency: String, exchange: String?, period: APIChartPeriod, limit: Int)
    case marketStats(symbol: String, currency: String)
    case rateLimit
    
    var path: String {
        switch self {
        case .priceMulti:
            return "/v2/tb/price/ticker"
        case .priceHistorical:
            return "/v2/tb/price/ticker/ohlc"
        case .priceStream:
            return "/v2/tb/price/ticker"
        case .ohlcv:
            return "/v2/tb/price/ticker/ohlc"
        case .marketStats:
            return "/v2/tb/price/ticker"
        case .rateLimit:
            return "/v2/tb/meta/ratelimit"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .priceMulti, .priceHistorical, .priceStream, .ohlcv, .marketStats, .rateLimit:
            return .GET
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .priceMulti(let symbols, let currencies):
            return [
                URLQueryItem(name: "symbols", value: symbols.joined(separator: ",")),
                URLQueryItem(name: "currencies", value: currencies.joined(separator: ","))
            ]
            
        case .priceHistorical(let symbol, let currency, let exchange, let period, let limit):
            var items = [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "currency", value: currency),
                URLQueryItem(name: "period", value: period.rawValue),
                URLQueryItem(name: "limit", value: String(limit))
            ]
            if let exchange = exchange {
                items.append(URLQueryItem(name: "exchange", value: exchange))
            }
            return items
            
        case .priceStream(let symbols, let currencies, let exchange):
            var items = [
                URLQueryItem(name: "symbols", value: symbols.joined(separator: ",")),
                URLQueryItem(name: "currencies", value: currencies.joined(separator: ","))
            ]
            if let exchange = exchange {
                items.append(URLQueryItem(name: "exchange", value: exchange))
            }
            return items
            
        case .ohlcv(let symbol, let currency, let exchange, let period, let limit):
            var items = [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "currency", value: currency),
                URLQueryItem(name: "period", value: period.rawValue),
                URLQueryItem(name: "limit", value: String(limit))
            ]
            if let exchange = exchange {
                items.append(URLQueryItem(name: "exchange", value: exchange))
            }
            return items
            
        case .marketStats(let symbol, let currency):
            return [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "currency", value: currency)
            ]
            
        case .rateLimit:
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
        return nil
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