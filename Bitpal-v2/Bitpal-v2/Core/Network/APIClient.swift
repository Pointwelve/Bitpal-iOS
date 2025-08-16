//
//  APIClient.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

// Use explicit typealias to resolve type ambiguity
typealias APINetworkError = NetworkError
typealias APIChartPeriod = ChartPeriod

actor APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var _apiKey: String
    private var _baseURL: URL
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self._apiKey = "" // Will be loaded from configuration
        guard let baseURL = URL(string: "https://data-api.coindesk.com") else {
            fatalError("Invalid base URL")
        }
        self._baseURL = baseURL
        
        // Setup date formatters
        decoder.dateDecodingStrategy = .secondsSince1970
        encoder.dateEncodingStrategy = .secondsSince1970
    }
    
    func setAPIKey(_ key: String) {
        _apiKey = key
    }
    
    func setBaseURL(_ url: URL) {
        _baseURL = url
    }
    
    var baseURL: URL {
        return _baseURL
    }
    
    var apiKey: String {
        return _apiKey
    }
    
    func buildRequest(endpoint: any APIEndpoint) throws -> URLRequest {
        return try buildRequest(for: endpoint)
    }
    
    func request<T: Decodable>(_ endpoint: any APIEndpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APINetworkError.invalidResponse
            }
            
            try validateResponse(httpResponse)
            
            guard !data.isEmpty else {
                throw APINetworkError.noData
            }
            
            return try decoder.decode(T.self, from: data)
        } catch let error as APINetworkError {
            throw error
        } catch {
            if let urlError = error as? URLError {
                throw mapURLError(urlError)
            }
            throw APINetworkError.unknown(error)
        }
    }
    
    private func buildRequest(for endpoint: any APIEndpoint) throws -> URLRequest {
        guard let url = endpoint.url(baseURL: _baseURL, apiKey: _apiKey) else {
            throw APINetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        if let body = endpoint.body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    private func validateResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APINetworkError.unauthorized
        case 429:
            throw APINetworkError.rateLimitExceeded
        case 500...599:
            throw APINetworkError.serverUnavailable
        default:
            throw APINetworkError.httpError(statusCode: response.statusCode)
        }
    }
    
    private func mapURLError(_ error: URLError) -> APINetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        case .cannotFindHost, .cannotConnectToHost:
            return .serverUnavailable
        default:
            return .unknown(error)
        }
    }
}

enum HTTPMethod: String, Sendable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

protocol APIEndpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
    var body: [String: Any]? { get }
    
    func url(baseURL: URL, apiKey: String) -> URL?
}

extension APIEndpoint {
    var headers: [String: String]? {
        [
            "Accept": "application/json",
            "User-Agent": "Bitpal-iOS/2.0"
        ]
    }
    
    var body: [String: Any]? {
        nil
    }
    
    func url(baseURL: URL, apiKey: String) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        
        var items = queryItems ?? []
        
        // Add API key only for endpoints that specifically require it
        if let cryptoEndpoint = self as? CryptoAPIEndpoint, cryptoEndpoint.requiresAPIKey && !apiKey.isEmpty {
            items.append(URLQueryItem(name: "api_key", value: apiKey))
        }
        
        if !items.isEmpty {
            components?.queryItems = items
        }
        
        return components?.url
    }
}

// API Endpoints
enum CryptoAPIEndpoint: APIEndpoint {
    
    // MARK: - API Key Requirements
    var requiresAPIKey: Bool {
        switch self {
        case .topList, .topListTrending:
            return false // Top list endpoints work without authentication
        case .priceMulti, .priceHistorical:
            return true // Price endpoints need authentication for WebSocket
        default:
            return false // Most endpoints work without API key
        }
    }
    // CoinDesk API
    case priceMulti(symbols: [String], currencies: [String])
    case priceHistorical(symbol: String, currency: String, exchange: String?, period: APIChartPeriod, limit: Int)
    case coinList
    case exchangeList
    case topCoins(limit: Int, currency: String)
    case topList(page: Int, pageSize: Int)
    case topListTrending(page: Int, pageSize: Int)
    case trendingCoins
    case validateCurrencyPair(CurrencyPairValidationRequest)
    case priceStream(symbols: [String], currencies: [String], exchange: String?)
    case ohlcv(symbol: String, currency: String, exchange: String?, period: APIChartPeriod, limit: Int)
    case topExchanges(currency: String)
    case marketStats(symbol: String, currency: String)
    case socialStats(symbol: String)
    case miningStats(symbol: String)
    case news(categories: [String]?, excludeCategories: [String]?, sources: [String]?, lang: String?)
    case rateLimit
    
    // Portfolio & User Data
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
    
    // Alerts
    case alerts
    case alert(String)
    case createAlert(APICreateAlertRequest)
    case updateAlert(String, APIUpdateAlertRequest)
    case deleteAlert(String)
    case alertHistory(String)
    
    // User & Settings
    case userProfile
    case updateUserProfile(UpdateUserProfileRequest)
    case userPreferences
    case updateUserPreferences(UpdateUserPreferencesRequest)
    case apiUsage
    
    // Sync & Backup
    case sync(entityType: String)
    case syncOperation(SyncOperation)
    case backup
    case restore(RestoreRequest)
    
    // Analytics & Reports
    case portfolioAnalytics(portfolioId: String, period: String)
    case performanceReport(portfolioId: String, startDate: Date, endDate: Date)
    case taxReport(portfolioId: String, year: Int)
    case exportData(format: String)
    
    // Search & Discovery
    case searchCurrencies(query: String, limit: Int)
    case searchExchanges(query: String, limit: Int)
    case currencyDetails(symbol: String)
    case exchangeDetails(exchangeId: String)
    case marketPairs(symbol: String)
    
    // Watchlist
    case watchlists
    case watchlist(String)
    case createWatchlist(CreateWatchlistRequest)
    case updateWatchlist(String, UpdateWatchlistRequest)
    case deleteWatchlist(String)
    case addToWatchlist(watchlistId: String, currencyPairId: String)
    case removeFromWatchlist(watchlistId: String, currencyPairId: String)
    
    var path: String {
        switch self {
        // CoinDesk API
        case .priceMulti:
            return "/index/cc/v1/latest/tick"
        case .priceHistorical(_, _, _, let period, _):
            switch period {
            case .oneMinute, .fiveMinutes, .fifteenMinutes, .thirtyMinutes:
                return "/index/cc/v1/historical/minutes"
            case .oneHour, .fourHours:
                return "/index/cc/v1/historical/hours"
            case .oneDay, .oneWeek, .oneMonth:
                return "/index/cc/v1/historical/days"
            }
        case .coinList:
            // TODO: No direct CoinDesk equivalent - may need alternative data source
            return "/v2/crypto/currencies"
        case .exchangeList:
            // TODO: No direct CoinDesk equivalent - may need alternative data source
            return "/v2/crypto/exchanges"
        case .topCoins:
            // TODO: No direct CoinDesk equivalent - may need alternative data source
            return "/v2/crypto/top"
        case .topList:
            return "/asset/v1/top/list"
        case .topListTrending:
            return "/asset/v1/top/list"
        case .trendingCoins:
            // TODO: No direct CoinDesk equivalent - may need alternative data source
            return "/v2/crypto/trending"
        case .validateCurrencyPair:
            // TODO: No direct CoinDesk equivalent - validation logic may need to be client-side
            return "/data/pair/mapping"
        case .priceStream:
            // TODO: CoinDesk may have WebSocket streaming - needs investigation
            return "/v2/crypto/prices/stream"
        case .ohlcv:
            // This should use the same historical endpoints as priceHistorical
            return "/index/cc/v1/historical/days"
        case .topExchanges:
            // TODO: No direct CoinDesk equivalent - may need alternative data source
            return "/v2/crypto/exchanges/top"
        case .marketStats:
            // TODO: No direct CoinDesk equivalent - may need alternative data source  
            return "/v2/crypto/market/stats"
        case .socialStats:
            // TODO: No direct CoinDesk equivalent - may need alternative data source
            return "/data/social/coin/histo/day"
        case .miningStats:
            // TODO: No direct CoinDesk equivalent - may need alternative data source
            return "/data/mining/pools/stats"
        case .news:
            // TODO: No direct CoinDesk equivalent - may need alternative news API
            return "/v2/news"
        case .rateLimit:
            return "/stats/rate/limit"
            
        // Portfolio & User Data
        case .portfolios:
            return "/api/v1/portfolios"
        case .portfolio(let id):
            return "/api/v1/portfolios/\(id)"
        case .createPortfolio:
            return "/api/v1/portfolios"
        case .updatePortfolio(let id, _):
            return "/api/v1/portfolios/\(id)"
        case .deletePortfolio(let id):
            return "/api/v1/portfolios/\(id)"
        case .holdings(let portfolioId):
            return "/api/v1/portfolios/\(portfolioId)/holdings"
        case .createHolding(let portfolioId, _):
            return "/api/v1/portfolios/\(portfolioId)/holdings"
        case .updateHolding(let portfolioId, let holdingId, _):
            return "/api/v1/portfolios/\(portfolioId)/holdings/\(holdingId)"
        case .deleteHolding(let portfolioId, let holdingId):
            return "/api/v1/portfolios/\(portfolioId)/holdings/\(holdingId)"
        case .transactions(let portfolioId):
            return "/api/v1/portfolios/\(portfolioId)/transactions"
        case .createTransaction(let portfolioId, _):
            return "/api/v1/portfolios/\(portfolioId)/transactions"
        case .updateTransaction(let portfolioId, let transactionId, _):
            return "/api/v1/portfolios/\(portfolioId)/transactions/\(transactionId)"
        case .deleteTransaction(let portfolioId, let transactionId):
            return "/api/v1/portfolios/\(portfolioId)/transactions/\(transactionId)"
            
        // Alerts
        case .alerts:
            return "/api/v1/alerts"
        case .alert(let id):
            return "/api/v1/alerts/\(id)"
        case .createAlert:
            return "/api/v1/alerts"
        case .updateAlert(let id, _):
            return "/api/v1/alerts/\(id)"
        case .deleteAlert(let id):
            return "/api/v1/alerts/\(id)"
        case .alertHistory(let id):
            return "/api/v1/alerts/\(id)/history"
            
        // User & Settings
        case .userProfile:
            return "/api/v1/user/profile"
        case .updateUserProfile:
            return "/api/v1/user/profile"
        case .userPreferences:
            return "/api/v1/user/preferences"
        case .updateUserPreferences:
            return "/api/v1/user/preferences"
        case .apiUsage:
            return "/api/v1/user/usage"
            
        // Sync & Backup
        case .sync(let entityType):
            return "/api/v1/sync/\(entityType)"
        case .syncOperation:
            return "/api/v1/sync/operations"
        case .backup:
            return "/api/v1/backup"
        case .restore:
            return "/api/v1/restore"
            
        // Analytics & Reports
        case .portfolioAnalytics(let portfolioId, _):
            return "/api/v1/portfolios/\(portfolioId)/analytics"
        case .performanceReport(let portfolioId, _, _):
            return "/api/v1/portfolios/\(portfolioId)/performance"
        case .taxReport(let portfolioId, _):
            return "/api/v1/portfolios/\(portfolioId)/tax-report"
        case .exportData:
            return "/api/v1/export"
            
        // Search & Discovery
        case .searchCurrencies:
            // TODO: No direct CoinDesk equivalent - may need alternative search API
            return "/data/search/currencies"
        case .searchExchanges:
            // TODO: No direct CoinDesk equivalent - may need alternative search API
            return "/data/search/exchanges"
        case .currencyDetails(let symbol):
            // TODO: No direct CoinDesk equivalent - may need alternative coin data API
            return "/data/coin/\(symbol)"
        case .exchangeDetails(let exchangeId):
            // TODO: No direct CoinDesk equivalent - may need alternative exchange data API
            return "/data/exchange/\(exchangeId)"
        case .marketPairs:
            // TODO: No direct CoinDesk equivalent - may need alternative market data API
            return "/data/pairs"
            
        // Watchlist
        case .watchlists:
            return "/api/v1/watchlists"
        case .watchlist(let id):
            return "/api/v1/watchlists/\(id)"
        case .createWatchlist:
            return "/api/v1/watchlists"
        case .updateWatchlist(let id, _):
            return "/api/v1/watchlists/\(id)"
        case .deleteWatchlist(let id):
            return "/api/v1/watchlists/\(id)"
        case .addToWatchlist(let watchlistId, _):
            return "/api/v1/watchlists/\(watchlistId)/items"
        case .removeFromWatchlist(let watchlistId, let currencyPairId):
            return "/api/v1/watchlists/\(watchlistId)/items/\(currencyPairId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .createPortfolio, .createHolding, .createTransaction, .createAlert, .createWatchlist,
             .syncOperation, .restore, .addToWatchlist:
            return .POST
        case .updatePortfolio, .updateHolding, .updateTransaction, .updateAlert, .updateUserProfile,
             .updateUserPreferences, .updateWatchlist:
            return .PUT
        case .deletePortfolio, .deleteHolding, .deleteTransaction, .deleteAlert, .deleteWatchlist,
             .removeFromWatchlist:
            return .DELETE
        default:
            return .GET
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .priceMulti(let symbols, let currencies):
            // Convert symbols and currencies to CoinDesk format (e.g., "BTC-USD")
            let instruments = symbols.flatMap { symbol in
                currencies.map { currency in
                    "\(symbol)-\(currency)"
                }
            }
            return [
                URLQueryItem(name: "market", value: "cadli"),
                URLQueryItem(name: "instruments", value: instruments.joined(separator: ","))
            ]
        case .priceHistorical(let symbol, let currency, _, _, let limit):
            let instrument = "\(symbol)-\(currency)"
            return [
                URLQueryItem(name: "market", value: "cadli"),
                URLQueryItem(name: "instrument", value: instrument),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        case .topCoins(let limit, let currency):
            return [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "tsym", value: currency)
            ]
        case .topList(let page, let pageSize):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: String(pageSize)),
                URLQueryItem(name: "sort_by", value: "CIRCULATING_MKT_CAP_USD"),
                URLQueryItem(name: "sort_direction", value: "DESC"),
                URLQueryItem(name: "groups", value: "ID,BASIC,SUPPLY,PRICE,MKT_CAP,VOLUME,CHANGE,TOPLIST_RANK"),
                URLQueryItem(name: "toplist_quote_asset", value: "USD")
            ]
        case .topListTrending(let page, let pageSize):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: String(pageSize)),
                URLQueryItem(name: "sort_by", value: "SPOT_MOVING_24_HOUR_CHANGE_PERCENTAGE_USD"),
                URLQueryItem(name: "sort_direction", value: "DESC"),
                URLQueryItem(name: "groups", value: "ID,BASIC,SUPPLY,PRICE,MKT_CAP,VOLUME,CHANGE,TOPLIST_RANK"),
                URLQueryItem(name: "toplist_quote_asset", value: "USD")
            ]
        case .priceStream(let symbols, let currencies, let exchangeParam):
            var items = [
                URLQueryItem(name: "fsyms", value: symbols.joined(separator: ",")),
                URLQueryItem(name: "tsyms", value: currencies.joined(separator: ","))
            ]
            if let exchangeParam = exchangeParam {
                items.append(URLQueryItem(name: "e", value: exchangeParam))
            }
            return items
        case .news(let categories, let excludeCategories, let sources, let lang):
            var items: [URLQueryItem] = []
            if let categories = categories {
                items.append(URLQueryItem(name: "categories", value: categories.joined(separator: ",")))
            }
            if let excludeCategories = excludeCategories {
                items.append(URLQueryItem(name: "excludeCategories", value: excludeCategories.joined(separator: ",")))
            }
            if let sources = sources {
                items.append(URLQueryItem(name: "sources", value: sources.joined(separator: ",")))
            }
            if let lang = lang {
                items.append(URLQueryItem(name: "lang", value: lang))
            }
            return items
        case .searchCurrencies(let query, let limit):
            return [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        case .searchExchanges(let query, let limit):
            return [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        case .marketPairs(let symbol):
            return [URLQueryItem(name: "fsym", value: symbol)]
        case .validateCurrencyPair(let request):
            return [
                URLQueryItem(name: "fsym", value: request.baseCurrency),
                URLQueryItem(name: "tsym", value: request.quoteCurrency),
                URLQueryItem(name: "e", value: request.exchange)
            ]
        case .portfolioAnalytics(_, let period):
            return [URLQueryItem(name: "period", value: period)]
        case .performanceReport(_, let startDate, let endDate):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return [
                URLQueryItem(name: "start_date", value: formatter.string(from: startDate)),
                URLQueryItem(name: "end_date", value: formatter.string(from: endDate))
            ]
        case .taxReport(_, let year):
            return [URLQueryItem(name: "year", value: String(year))]
        case .exportData(let format):
            return [URLQueryItem(name: "format", value: format)]
        case .ohlcv(let symbol, let currency, _, _, let limit):
            let instrument = "\(symbol)-\(currency)"
            return [
                URLQueryItem(name: "market", value: "cadli"),
                URLQueryItem(name: "instrument", value: instrument),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        default:
            return nil
        }
    }
    
    var body: [String: Any]? {
        switch self {
        case .createPortfolio(let request):
            return try? request.asDictionary()
        case .updatePortfolio(_, let request):
            return try? request.asDictionary()
        case .createHolding(_, let request):
            return try? request.asDictionary()
        case .updateHolding(_, _, let request):
            return try? request.asDictionary()
        case .createTransaction(_, let request):
            return try? request.asDictionary()
        case .updateTransaction(_, _, let request):
            return try? request.asDictionary()
        case .createAlert(let request):
            return try? request.asDictionary()
        case .updateAlert(_, let request):
            return try? request.asDictionary()
        case .updateUserProfile(let request):
            return try? request.asDictionary()
        case .updateUserPreferences(let request):
            return try? request.asDictionary()
        case .syncOperation(let operation):
            return try? operation.asDictionary()
        case .restore(let request):
            return try? request.asDictionary()
        case .createWatchlist(let request):
            return try? request.asDictionary()
        case .updateWatchlist(_, let request):
            return try? request.asDictionary()
        case .addToWatchlist(_, let currencyPairId):
            return ["currency_pair_id": currencyPairId]
        default:
            return nil
        }
    }
}
