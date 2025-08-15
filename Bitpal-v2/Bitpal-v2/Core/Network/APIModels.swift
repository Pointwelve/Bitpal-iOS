//
//  APIModels.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation

// MARK: - Portfolio API Models

struct CreatePortfolioRequest: Codable {
    let name: String
    let isDefault: Bool
}

struct UpdatePortfolioRequest: Codable {
    let name: String?
    let isDefault: Bool?
}

struct CreateHoldingRequest: Codable {
    let currencyId: String
    let quantity: Double
    let averageCost: Double
    let notes: String?
}

struct UpdateHoldingRequest: Codable {
    let quantity: Double?
    let averageCost: Double?
    let notes: String?
}

struct CreateTransactionRequest: Codable {
    let currencyId: String
    let type: String
    let quantity: Double
    let price: Double
    let fee: Double?
    let exchange: String?
    let notes: String?
    let timestamp: Date?
    let txHash: String?
}

struct UpdateTransactionRequest: Codable {
    let quantity: Double?
    let price: Double?
    let fee: Double?
    let exchange: String?
    let notes: String?
    let timestamp: Date?
    let txHash: String?
}

// MARK: - Alert API Models

struct APICreateAlertRequest: Codable {
    let currencyPairId: String
    let comparison: String
    let targetPrice: Double
    let message: String?
    let isEnabled: Bool
}

struct APIUpdateAlertRequest: Codable {
    let comparison: String?
    let targetPrice: Double?
    let message: String?
    let isEnabled: Bool?
}

// MARK: - User API Models

struct UpdateUserProfileRequest: Codable {
    let displayName: String?
    let email: String?
    let timezone: String?
    let currency: String?
}

struct UpdateUserPreferencesRequest: Codable {
    let theme: String?
    let language: String?
    let enableNotifications: Bool?
    let enableLiveActivities: Bool?
    let soundEnabled: Bool?
    let hapticEnabled: Bool?
}

// MARK: - Watchlist API Models

struct CreateWatchlistRequest: Codable {
    let name: String
    let description: String?
    let isPublic: Bool
}

struct UpdateWatchlistRequest: Codable {
    let name: String?
    let description: String?
    let isPublic: Bool?
}

// MARK: - Sync API Models

struct RestoreRequest: Codable {
    let backupId: String
    let timestamp: Date
    let overwriteLocal: Bool
}

// MARK: - Historical Data API Models

struct APIHistoricalDataRequest: Codable {
    let symbol: String
    let currency: String
    let exchange: String?
    let period: String
    let limit: Int
}

struct APIHistoricalDataResponse: Codable {
    let data: [CoinDeskHistoricalPoint]
    
    private enum CodingKeys: String, CodingKey {
        case data = "Data"
    }
}

struct CoinDeskHistoricalPoint: Codable {
    let timestamp: Int
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let quoteVolume: Double
    let instrument: String
    let market: String
    
    private enum CodingKeys: String, CodingKey {
        case timestamp = "TIMESTAMP"
        case open = "OPEN"
        case high = "HIGH"
        case low = "LOW"
        case close = "CLOSE"
        case volume = "VOLUME"
        case quoteVolume = "QUOTE_VOLUME"
        case instrument = "INSTRUMENT"
        case market = "MARKET"
    }
}

// Legacy compatibility for existing code
typealias APIHistoricalDataPoint = CoinDeskHistoricalPoint

extension CoinDeskHistoricalPoint {
    // Compatibility properties for legacy code
    var time: Int { timestamp }
    var volumeFrom: Double { volume }
    var volumeTo: Double { quoteVolume }
}

// MARK: - Price API Models

struct PriceMultiResponse: Codable {
    let data: [String: CoinDeskTickData]
    
    private enum CodingKeys: String, CodingKey {
        case data = "Data"
    }
}

struct CoinDeskTickData: Codable {
    let instrument: String
    let value: Double
    let valueFlag: String?
    let market: String
    let currentDayOpen: Double?
    let currentDayHigh: Double?
    let currentDayLow: Double?
    let currentDayChange: Double?
    let currentDayChangePercentage: Double?
    
    private enum CodingKeys: String, CodingKey {
        case instrument = "INSTRUMENT"
        case value = "VALUE"
        case valueFlag = "VALUE_FLAG"
        case market = "MARKET"
        case currentDayOpen = "CURRENT_DAY_OPEN"
        case currentDayHigh = "CURRENT_DAY_HIGH"
        case currentDayLow = "CURRENT_DAY_LOW"
        case currentDayChange = "CURRENT_DAY_CHANGE"
        case currentDayChangePercentage = "CURRENT_DAY_CHANGE_PERCENTAGE"
    }
}

// Legacy compatibility - keep for historical data
struct CoinDeskOHLC: Codable {
    let o: Double // open
    let h: Double // high
    let l: Double // low
    let c: Double // close
    
    private enum CodingKeys: String, CodingKey {
        case o, h, l, c
    }
}

struct TopCoinsResponse: Codable {
    let data: [TopCoinData]
    let hasWarning: Bool
    
    private enum CodingKeys: String, CodingKey {
        case data = "Data"
        case hasWarning = "HasWarning"
    }
}

struct TopCoinData: Codable {
    let coinInfo: CoinInfo
    let display: [String: CoinDisplayData]
    let raw: [String: CoinRawData]
    
    private enum CodingKeys: String, CodingKey {
        case coinInfo = "CoinInfo"
        case display = "DISPLAY"
        case raw = "RAW"
    }
}

struct CoinInfo: Codable {
    let id: String
    let name: String
    let fullName: String
    let imageUrl: String
    let type: Int
    
    private enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case fullName = "FullName"
        case imageUrl = "ImageUrl"
        case type = "Type"
    }
}

struct CoinDisplayData: Codable {
    let price: String
    let change24h: String
    let changePct24h: String
    let high24h: String
    let low24h: String
    let volume24h: String
    let market24h: String
    
    private enum CodingKeys: String, CodingKey {
        case price = "PRICE"
        case change24h = "CHANGE24HOUR"
        case changePct24h = "CHANGEPCT24HOUR"
        case high24h = "HIGH24HOUR"
        case low24h = "LOW24HOUR"
        case volume24h = "VOLUME24HOURTO"
        case market24h = "MKTCAP"
    }
}

struct CoinRawData: Codable {
    let price: Double
    let change24h: Double
    let changePct24h: Double
    let high24h: Double
    let low24h: Double
    let volume24h: Double
    let market24h: Double
    let supply: Double
    let lastUpdate: Int
    
    private enum CodingKeys: String, CodingKey {
        case price = "PRICE"
        case change24h = "CHANGE24HOUR"
        case changePct24h = "CHANGEPCT24HOUR"
        case high24h = "HIGH24HOUR"
        case low24h = "LOW24HOUR"
        case volume24h = "VOLUME24HOURTO"
        case market24h = "MKTCAP"
        case supply = "SUPPLY"
        case lastUpdate = "LASTUPDATE"
    }
}

// MARK: - Exchange API Models

struct APIExchangeListResponse: Codable {
    let data: [String: APIExchangeData]
    
    private enum CodingKeys: String, CodingKey {
        case data = "Data"
    }
}

struct APIExchangeData: Codable {
    let name: String
    let url: String
    let logoUrl: String
    let isActive: Bool
    let centralizedDecentralized: String
    let internalName: String
    
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case url = "Url"
        case logoUrl = "LogoUrl"
        case isActive = "IsActive"
        case centralizedDecentralized = "CentralizedDecentralized"
        case internalName = "InternalName"
    }
}

// MARK: - News API Models (detailed models moved to SearchModels.swift)

struct SourceInfo: Codable {
    let name: String
    let lang: String
    let img: String
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case lang = "lang"
        case img = "img"
    }
}

struct RateLimit: Codable {
    let callsLeft: CallsLeft
    let callsMade: CallsMade
    
    private enum CodingKeys: String, CodingKey {
        case callsLeft = "calls_left"
        case callsMade = "calls_made"
    }
}

struct CallsLeft: Codable {
    let histo: Int
    let price: Int
    let news: Int
    let strict: Int
    
    private enum CodingKeys: String, CodingKey {
        case histo = "Histo"
        case price = "Price"
        case news = "News"
        case strict = "Strict"
    }
}

struct CallsMade: Codable {
    let histo: Int
    let price: Int
    let news: Int
    let strict: Int
    
    private enum CodingKeys: String, CodingKey {
        case histo = "Histo"
        case price = "Price"
        case news = "News"
        case strict = "Strict"
    }
}

// MARK: - Search API Models (moved to SearchModels.swift)

// MARK: - Analytics API Models

struct PortfolioAnalyticsResponse: Codable {
    let totalValue: Double
    let totalCost: Double
    let totalProfitLoss: Double
    let totalProfitLossPercent: Double
    let bestPerformer: HoldingPerformance?
    let worstPerformer: HoldingPerformance?
    let topHoldings: [HoldingPerformance]
    let allocationChart: [AllocationData]
    let performanceChart: [PerformanceData]
}

struct HoldingPerformance: Codable {
    let holdingId: String
    let currencySymbol: String
    let currencyName: String
    let quantity: Double
    let currentValue: Double
    let profitLoss: Double
    let profitLossPercent: Double
    let allocationPercent: Double
}

struct AllocationData: Codable {
    let currencySymbol: String
    let currencyName: String
    let value: Double
    let percentage: Double
}

struct PerformanceData: Codable {
    let date: String
    let value: Double
    let profitLoss: Double
    let profitLossPercent: Double
}

struct PerformanceReportResponse: Codable {
    let portfolioId: String
    let startDate: String
    let endDate: String
    let totalReturn: Double
    let totalReturnPercent: Double
    let bestDay: DayPerformance?
    let worstDay: DayPerformance?
    let volatility: Double
    let sharpeRatio: Double?
    let maxDrawdown: Double
    let dailyReturns: [DailyReturn]
}

struct DayPerformance: Codable {
    let date: String
    let value: Double
    let change: Double
    let changePercent: Double
}

struct DailyReturn: Codable {
    let date: String
    let dailyReturn: Double
    let returnPercent: Double
    
    private enum CodingKeys: String, CodingKey {
        case date
        case dailyReturn = "return"
        case returnPercent
    }
}

// MARK: - Tax Report API Models

struct TaxReportResponse: Codable {
    let portfolioId: String
    let year: Int
    let currency: String
    let totalGains: Double
    let totalLosses: Double
    let netGains: Double
    let shortTermGains: Double
    let longTermGains: Double
    let transactions: [TaxTransaction]
    let summary: TaxSummary
}

struct TaxTransaction: Codable {
    let transactionId: String
    let date: String
    let type: String
    let currency: String
    let quantity: Double
    let price: Double
    let value: Double
    let gainLoss: Double?
    let costBasis: Double?
    let holdingPeriod: Int?
    let taxCategory: String?
}

struct TaxSummary: Codable {
    let totalTransactions: Int
    let totalBuys: Int
    let totalSells: Int
    let totalGains: Double
    let totalLosses: Double
    let netGains: Double
    let taxableEvents: Int
}

// MARK: - User Profile API Models

struct UserProfileResponse: Codable {
    let id: String
    let displayName: String
    let email: String
    let timezone: String
    let currency: String
    let createdAt: String
    let lastLoginAt: String?
    let subscription: SubscriptionInfo?
}

struct SubscriptionInfo: Codable {
    let tier: String
    let isActive: Bool
    let expiresAt: String?
    let features: [String]
}

struct APIUsageResponse: Codable {
    let currentPeriod: UsagePeriod
    let limits: UsageLimits
    let history: [UsageHistory]
}

struct UsagePeriod: Codable {
    let startDate: String
    let endDate: String
    let apiCalls: Int
    let dataRequests: Int
    let websocketConnections: Int
}

struct UsageLimits: Codable {
    let apiCallsPerMonth: Int
    let dataRequestsPerDay: Int
    let websocketConnectionsPerDay: Int
    let concurrentConnections: Int
}

struct UsageHistory: Codable {
    let date: String
    let apiCalls: Int
    let dataRequests: Int
    let websocketConnections: Int
}

// MARK: - Generic API Response Models

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIError?
    let timestamp: Date
    let requestId: String?
}

struct APIError: Codable {
    let code: String
    let message: String
    let details: [String: String]?
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: PaginationInfo
    let total: Int
}

struct PaginationInfo: Codable {
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

// MARK: - CoinDesk Top List API Models

struct CoinDeskTopListResponse: Codable {
    let data: CoinDeskTopListData
    let err: CoinDeskError?
    
    private enum CodingKeys: String, CodingKey {
        case data = "Data"
        case err = "Err"
    }
}

struct CoinDeskTopListData: Codable {
    let stats: TopListStats
    let list: [TopListCurrency]
    
    private enum CodingKeys: String, CodingKey {
        case stats = "STATS"
        case list = "LIST"
    }
}

struct TopListStats: Codable {
    let page: Int
    let pageSize: Int
    let totalAssets: Int
    
    private enum CodingKeys: String, CodingKey {
        case page = "PAGE"
        case pageSize = "PAGE_SIZE"
        case totalAssets = "TOTAL_ASSETS"
    }
}

struct TopListCurrency: Codable {
    let id: Int
    let symbol: String
    let name: String
    let logoUrl: String?
    let priceUsd: Double?
    let circulatingMarketCapUsd: Double?
    let change24hPercentage: Double?
    let topListBaseRank: TopListBaseRank?
    
    private enum CodingKeys: String, CodingKey {
        case id = "ID"
        case symbol = "SYMBOL"
        case name = "NAME"
        case logoUrl = "LOGO_URL"
        case priceUsd = "PRICE_USD"
        case circulatingMarketCapUsd = "CIRCULATING_MKT_CAP_USD"
        case change24hPercentage = "SPOT_MOVING_24_HOUR_CHANGE_PERCENTAGE_USD"
        case topListBaseRank = "TOPLIST_BASE_RANK"
    }
    
    var marketCapRank: Int? {
        return topListBaseRank?.circulatingMktCapUsd
    }
}

struct TopListBaseRank: Codable {
    let circulatingMktCapUsd: Int?
    let totalMktCapUsd: Int?
    let createdOn: Int?
    
    private enum CodingKeys: String, CodingKey {
        case circulatingMktCapUsd = "CIRCULATING_MKT_CAP_USD"
        case totalMktCapUsd = "TOTAL_MKT_CAP_USD"
        case createdOn = "CREATED_ON"
    }
}

struct CoinDeskError: Codable {
    let type: Int?
    let message: String?
    let otherInfo: [String: String]?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case message
        case otherInfo = "other_info"
    }
}

// MARK: - Codable Extensions

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
}