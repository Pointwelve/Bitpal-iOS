//
//  UserDataEndpoints.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

enum UserDataEndpoints: APIEndpoint {
    // Portfolio & Holdings
    case portfolios
    case portfolio(String)
    case createPortfolio(CreatePortfolioRequest)
    case updatePortfolio(String, UpdatePortfolioRequest)
    case deletePortfolio(String)
    case holdings(portfolioId: String)
    case createHolding(portfolioId: String, CreateHoldingRequest)
    case updateHolding(portfolioId: String, holdingId: String, UpdateHoldingRequest)
    case deleteHolding(portfolioId: String, holdingId: String)
    case transactions(portfolioId: String)
    case createTransaction(portfolioId: String, CreateTransactionRequest)
    case updateTransaction(portfolioId: String, transactionId: String, UpdateTransactionRequest)
    case deleteTransaction(portfolioId: String, transactionId: String)
    
    // Watchlists
    case watchlists
    case watchlist(String)
    case createWatchlist(CreateWatchlistRequest)
    case updateWatchlist(String, UpdateWatchlistRequest)
    case deleteWatchlist(String)
    
    // User Profile & Settings
    case userProfile
    case updateUserProfile(UpdateUserProfileRequest)
    case userPreferences
    case updateUserPreferences(UpdateUserPreferencesRequest)
    case apiUsage
    
    var path: String {
        switch self {
        case .portfolios:
            return "/v1/portfolios"
        case .portfolio(let id):
            return "/v1/portfolios/\(id)"
        case .createPortfolio:
            return "/v1/portfolios"
        case .updatePortfolio(let id, _):
            return "/v1/portfolios/\(id)"
        case .deletePortfolio(let id):
            return "/v1/portfolios/\(id)"
        case .holdings(let portfolioId):
            return "/v1/portfolios/\(portfolioId)/holdings"
        case .createHolding(let portfolioId, _):
            return "/v1/portfolios/\(portfolioId)/holdings"
        case .updateHolding(let portfolioId, let holdingId, _):
            return "/v1/portfolios/\(portfolioId)/holdings/\(holdingId)"
        case .deleteHolding(let portfolioId, let holdingId):
            return "/v1/portfolios/\(portfolioId)/holdings/\(holdingId)"
        case .transactions(let portfolioId):
            return "/v1/portfolios/\(portfolioId)/transactions"
        case .createTransaction(let portfolioId, _):
            return "/v1/portfolios/\(portfolioId)/transactions"
        case .updateTransaction(let portfolioId, let transactionId, _):
            return "/v1/portfolios/\(portfolioId)/transactions/\(transactionId)"
        case .deleteTransaction(let portfolioId, let transactionId):
            return "/v1/portfolios/\(portfolioId)/transactions/\(transactionId)"
        case .watchlists:
            return "/v1/watchlists"
        case .watchlist(let id):
            return "/v1/watchlists/\(id)"
        case .createWatchlist:
            return "/v1/watchlists"
        case .updateWatchlist(let id, _):
            return "/v1/watchlists/\(id)"
        case .deleteWatchlist(let id):
            return "/v1/watchlists/\(id)"
        case .userProfile:
            return "/v1/user/profile"
        case .updateUserProfile:
            return "/v1/user/profile"
        case .userPreferences:
            return "/v1/user/preferences"
        case .updateUserPreferences:
            return "/v1/user/preferences"
        case .apiUsage:
            return "/v1/user/api-usage"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .portfolios, .portfolio, .holdings, .transactions, .watchlists, .watchlist,
             .userProfile, .userPreferences, .apiUsage:
            return .GET
        case .createPortfolio, .createHolding, .createTransaction, .createWatchlist:
            return .POST
        case .updatePortfolio, .updateHolding, .updateTransaction, .updateWatchlist,
             .updateUserProfile, .updateUserPreferences:
            return .PUT
        case .deletePortfolio, .deleteHolding, .deleteTransaction, .deleteWatchlist:
            return .DELETE
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil // Most user data endpoints don't use query parameters
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var body: [String: Any]? {
        let encoder = JSONEncoder()
        
        switch self {
        case .createPortfolio(let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .updatePortfolio(_, let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .createHolding(_, let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .updateHolding(_, _, let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .createTransaction(_, let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .updateTransaction(_, _, let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .createWatchlist(let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .updateWatchlist(_, let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .updateUserProfile(let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        case .updateUserPreferences(let request):
            if let data = try? encoder.encode(request),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return dict
            }
        default:
            break
        }
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