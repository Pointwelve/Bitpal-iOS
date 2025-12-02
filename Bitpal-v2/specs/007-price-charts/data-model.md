# Data Model: Per-Coin Price Charts

**Feature**: 007-price-charts | **Date**: 2025-12-01 | **Phase**: 1 (Design)

## Entity Relationship Diagram

```
┌─────────────────────────┐
│       CoinDetail        │  Extended coin info for detail screen
├─────────────────────────┤
│ id: String              │  "bitcoin"
│ symbol: String          │  "btc"
│ name: String            │  "Bitcoin"
│ image: URL?             │  Logo URL
│ currentPrice: Decimal   │  Current USD price
│ priceChange24h: Decimal │  24h change %
│ marketCap: Decimal?     │  Market capitalization
│ totalVolume: Decimal?   │  24h trading volume
│ circulatingSupply: Decimal? │  Circulating supply
│ lastUpdated: Date       │  Last price update
└─────────────────────────┘
           │
           │ 1:N (fetched separately)
           ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│    ChartDataPoint       │     │    CandleDataPoint      │
│    (Line Chart)         │     │    (Candlestick)        │
├─────────────────────────┤     ├─────────────────────────┤
│ timestamp: Date         │     │ timestamp: Date         │
│ price: Decimal          │     │ open: Decimal           │
│                         │     │ high: Decimal           │
│                         │     │ low: Decimal            │
│                         │     │ close: Decimal          │
└─────────────────────────┘     └─────────────────────────┘
           │                               │
           └───────────┬───────────────────┘
                       │
                       ▼
           ┌─────────────────────────┐
           │   CachedChartData       │  Swift Data persistence
           │   (@Model)              │
           ├─────────────────────────┤
           │ cacheKey: String        │  "bitcoin-line-1D"
           │ pricesJSON: Data        │  Encoded chart data
           │ cachedAt: Date          │  When cached
           │ expiresAt: Date         │  Cache expiration
           └─────────────────────────┘

┌─────────────────────────┐     ┌─────────────────────────┐
│    ChartTimeRange       │     │      ChartType          │
│    (enum)               │     │      (enum)             │
├─────────────────────────┤     ├─────────────────────────┤
│ .fifteenMinutes = "15M" │     │ .line = "Line"          │
│ .oneHour = "1H"         │     │ .candle = "Candle"      │
│ .fourHours = "4H"       │     └─────────────────────────┘
│ .oneDay = "1D"          │
│ .oneWeek = "1W"         │
│ .oneMonth = "1M"        │
│ .oneYear = "1Y"         │
└─────────────────────────┘
```

---

## Model Definitions

### CoinDetail

Extended coin information for the detail screen. Builds on existing `Coin` model.

```swift
import Foundation

/// Extended coin details for the coin detail screen
/// Includes market statistics beyond basic price data
struct CoinDetail: Identifiable, Codable, Equatable {
    let id: String              // CoinGecko ID (e.g., "bitcoin")
    let symbol: String          // Trading symbol (e.g., "btc")
    let name: String            // Display name (e.g., "Bitcoin")
    let image: URL?             // Logo URL
    var currentPrice: Decimal   // Current USD price
    var priceChange24h: Decimal // 24-hour price change percentage
    var marketCap: Decimal?     // Market capitalization in USD
    var totalVolume: Decimal?   // 24-hour trading volume in USD
    var circulatingSupply: Decimal? // Coins in circulation
    var lastUpdated: Date       // Last price update timestamp

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice = "current_price"
        case priceChange24h = "price_change_percentage_24h"
        case marketCap = "market_cap"
        case totalVolume = "total_volume"
        case circulatingSupply = "circulating_supply"
        case lastUpdated = "last_updated"
    }

    // MARK: - Custom Decoding (Double → Decimal)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        image = try container.decodeIfPresent(URL.self, forKey: .image)

        // Convert Double to Decimal for financial accuracy
        let priceDouble = try container.decode(Double.self, forKey: .currentPrice)
        currentPrice = Decimal(priceDouble)

        let changeDouble = try container.decodeIfPresent(Double.self, forKey: .priceChange24h) ?? 0
        priceChange24h = Decimal(changeDouble)

        if let mcDouble = try container.decodeIfPresent(Double.self, forKey: .marketCap) {
            marketCap = Decimal(mcDouble)
        }

        if let volDouble = try container.decodeIfPresent(Double.self, forKey: .totalVolume) {
            totalVolume = Decimal(volDouble)
        }

        if let supplyDouble = try container.decodeIfPresent(Double.self, forKey: .circulatingSupply) {
            circulatingSupply = Decimal(supplyDouble)
        }

        let dateString = try container.decode(String.self, forKey: .lastUpdated)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        lastUpdated = formatter.date(from: dateString) ?? Date()
    }

    // MARK: - Memberwise Init (for testing)

    init(
        id: String,
        symbol: String,
        name: String,
        image: URL? = nil,
        currentPrice: Decimal,
        priceChange24h: Decimal,
        marketCap: Decimal? = nil,
        totalVolume: Decimal? = nil,
        circulatingSupply: Decimal? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.currentPrice = currentPrice
        self.priceChange24h = priceChange24h
        self.marketCap = marketCap
        self.totalVolume = totalVolume
        self.circulatingSupply = circulatingSupply
        self.lastUpdated = lastUpdated
    }
}
```

---

### ChartDataPoint

Single price point for line charts.

```swift
import Foundation

/// Represents a single price point in time for line charts
struct ChartDataPoint: Identifiable, Codable, Equatable {
    /// Unique identifier (uses timestamp)
    var id: Date { timestamp }

    /// Point in time (X-axis)
    let timestamp: Date

    /// Price at this timestamp (Y-axis)
    let price: Decimal

    // MARK: - Initialization

    init(timestamp: Date, price: Decimal) {
        self.timestamp = timestamp
        self.price = price
    }

    /// Create from CoinGecko API array [timestamp_ms, price]
    init?(from apiArray: [Double]) {
        guard apiArray.count >= 2 else { return nil }
        self.timestamp = Date(timeIntervalSince1970: apiArray[0] / 1000)
        self.price = Decimal(apiArray[1])
    }
}

// MARK: - Array Extension

extension Array where Element == [Double] {
    /// Convert CoinGecko prices array to ChartDataPoint array
    func toChartDataPoints() -> [ChartDataPoint] {
        compactMap { ChartDataPoint(from: $0) }
    }
}
```

---

### CandleDataPoint

OHLC data point for candlestick charts.

```swift
import Foundation

/// Represents OHLC (Open, High, Low, Close) data for candlestick charts
struct CandleDataPoint: Identifiable, Codable, Equatable {
    /// Unique identifier (uses timestamp)
    var id: Date { timestamp }

    /// Candle close time (X-axis)
    let timestamp: Date

    /// Opening price
    let open: Decimal

    /// Highest price during interval
    let high: Decimal

    /// Lowest price during interval
    let low: Decimal

    /// Closing price
    let close: Decimal

    // MARK: - Computed Properties

    /// True if candle closed higher than it opened (bullish)
    var isGreen: Bool { close >= open }

    /// True if candle closed lower than it opened (bearish)
    var isRed: Bool { close < open }

    /// Price movement during interval
    var priceChange: Decimal { close - open }

    /// Percentage change during interval
    var percentageChange: Decimal {
        guard open != 0 else { return 0 }
        return (priceChange / open) * 100
    }

    // MARK: - Initialization

    init(timestamp: Date, open: Decimal, high: Decimal, low: Decimal, close: Decimal) {
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
    }

    /// Create from CoinGecko OHLC API array [timestamp_ms, open, high, low, close]
    init?(from apiArray: [Double]) {
        guard apiArray.count >= 5 else { return nil }
        self.timestamp = Date(timeIntervalSince1970: apiArray[0] / 1000)
        self.open = Decimal(apiArray[1])
        self.high = Decimal(apiArray[2])
        self.low = Decimal(apiArray[3])
        self.close = Decimal(apiArray[4])
    }
}

// MARK: - Array Extension

extension Array where Element == [Double] {
    /// Convert CoinGecko OHLC array to CandleDataPoint array
    func toCandleDataPoints() -> [CandleDataPoint] {
        compactMap { CandleDataPoint(from: $0) }
    }
}
```

---

### ChartTimeRange

Enumeration of available time ranges with API mapping.

```swift
import Foundation

/// Available time ranges for price charts
enum ChartTimeRange: String, CaseIterable, Identifiable, Codable {
    case fifteenMinutes = "15M"
    case oneHour = "1H"
    case fourHours = "4H"
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case oneYear = "1Y"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// Human-readable label
    var displayName: String { rawValue }

    /// Full description for accessibility
    var accessibilityLabel: String {
        switch self {
        case .fifteenMinutes: return "15 minutes"
        case .oneHour: return "1 hour"
        case .fourHours: return "4 hours"
        case .oneDay: return "1 day"
        case .oneWeek: return "1 week"
        case .oneMonth: return "1 month"
        case .oneYear: return "1 year"
        }
    }

    // MARK: - API Mapping

    /// CoinGecko API `days` parameter value
    var apiDays: String {
        switch self {
        case .fifteenMinutes, .oneHour, .fourHours, .oneDay:
            return "1"
        case .oneWeek:
            return "7"
        case .oneMonth:
            return "30"
        case .oneYear:
            return "365"
        }
    }

    /// Maximum data points to display for performance
    var maxDataPoints: Int {
        switch self {
        case .fifteenMinutes: return 15
        case .oneHour: return 60
        case .fourHours: return 48
        case .oneDay: return 96
        case .oneWeek: return 42
        case .oneMonth: return 30
        case .oneYear: return 52
        }
    }

    // MARK: - Caching

    /// Cache time-to-live in seconds
    var cacheTTL: TimeInterval {
        switch self {
        case .fifteenMinutes, .oneHour, .fourHours:
            return 60          // 1 minute
        case .oneDay:
            return 300         // 5 minutes
        case .oneWeek:
            return 900         // 15 minutes
        case .oneMonth:
            return 1800        // 30 minutes
        case .oneYear:
            return 3600        // 1 hour
        }
    }

    /// Cache key suffix for this range
    var cacheKeySuffix: String { rawValue }

    // MARK: - Chart Type Availability

    /// Time ranges available for line charts (simpler, 5 options)
    static var lineRanges: [ChartTimeRange] {
        [.oneHour, .oneDay, .oneWeek, .oneMonth, .oneYear]
    }

    /// Time ranges available for candlestick charts (all 7 options)
    static var candleRanges: [ChartTimeRange] {
        allCases
    }

    /// Default time range
    static var defaultRange: ChartTimeRange { .oneDay }

    // MARK: - Data Filtering

    /// Filter data points to match this time range
    func filterDataPoints<T>(_ points: [T], timestampKeyPath: KeyPath<T, Date>) -> [T] {
        let cutoffDate: Date
        let now = Date()

        switch self {
        case .fifteenMinutes:
            cutoffDate = now.addingTimeInterval(-15 * 60)
        case .oneHour:
            cutoffDate = now.addingTimeInterval(-60 * 60)
        case .fourHours:
            cutoffDate = now.addingTimeInterval(-4 * 60 * 60)
        case .oneDay:
            cutoffDate = now.addingTimeInterval(-24 * 60 * 60)
        case .oneWeek:
            cutoffDate = now.addingTimeInterval(-7 * 24 * 60 * 60)
        case .oneMonth:
            cutoffDate = now.addingTimeInterval(-30 * 24 * 60 * 60)
        case .oneYear:
            cutoffDate = now.addingTimeInterval(-365 * 24 * 60 * 60)
        }

        return points.filter { $0[keyPath: timestampKeyPath] >= cutoffDate }
    }
}
```

---

### ChartType

Chart visualization type with preference persistence.

```swift
import Foundation

/// Chart visualization type
enum ChartType: String, CaseIterable, Identifiable, Codable {
    case line = "Line"
    case candle = "Candle"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// SF Symbol name for the chart type
    var iconName: String {
        switch self {
        case .line: return "chart.xyaxis.line"
        case .candle: return "chart.bar.fill"
        }
    }

    /// Human-readable label
    var displayName: String { rawValue }

    /// Accessibility description
    var accessibilityLabel: String {
        switch self {
        case .line: return "Line chart"
        case .candle: return "Candlestick chart"
        }
    }

    // MARK: - Available Time Ranges

    /// Time ranges available for this chart type
    var availableRanges: [ChartTimeRange] {
        switch self {
        case .line: return ChartTimeRange.lineRanges
        case .candle: return ChartTimeRange.candleRanges
        }
    }

    /// Check if a time range is available for this chart type
    func isRangeAvailable(_ range: ChartTimeRange) -> Bool {
        availableRanges.contains(range)
    }

    /// Find closest available range when switching chart types
    func closestAvailableRange(to range: ChartTimeRange) -> ChartTimeRange {
        if isRangeAvailable(range) {
            return range
        }

        // Find closest match
        switch range {
        case .fifteenMinutes, .fourHours:
            return .oneHour  // Closest to unavailable short ranges
        default:
            return availableRanges.first ?? .oneDay
        }
    }

    // MARK: - Persistence

    /// UserDefaults key for chart type preference
    private static let preferenceKey = "chartTypePreference"

    /// Save preferred chart type
    func saveAsPreference() {
        UserDefaults.standard.set(rawValue, forKey: Self.preferenceKey)
    }

    /// Load preferred chart type (defaults to .line)
    static func loadPreference() -> ChartType {
        guard let rawValue = UserDefaults.standard.string(forKey: preferenceKey),
              let chartType = ChartType(rawValue: rawValue) else {
            return .line  // Default for new users
        }
        return chartType
    }
}
```

---

### CachedChartData (Swift Data)

Persistent cache for chart data.

```swift
import Foundation
import SwiftData

/// Cached chart data for offline support
@Model
final class CachedChartData {
    /// Unique cache key: "{coinId}-{chartType}-{timeRange}"
    /// Example: "bitcoin-line-1D"
    @Attribute(.unique) var cacheKey: String

    /// JSON-encoded chart data ([ChartDataPoint] or [CandleDataPoint])
    var pricesJSON: Data

    /// When this data was cached
    var cachedAt: Date

    /// When this cache entry expires
    var expiresAt: Date

    // MARK: - Initialization

    init(cacheKey: String, pricesJSON: Data, ttl: TimeInterval) {
        self.cacheKey = cacheKey
        self.pricesJSON = pricesJSON
        self.cachedAt = Date()
        self.expiresAt = Date().addingTimeInterval(ttl)
    }

    // MARK: - Computed Properties

    /// True if cache has expired
    var isExpired: Bool {
        Date() > expiresAt
    }

    /// Time remaining until expiration
    var timeUntilExpiration: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }

    // MARK: - Factory Methods

    /// Create cache key from components
    static func makeCacheKey(coinId: String, chartType: ChartType, timeRange: ChartTimeRange) -> String {
        "\(coinId)-\(chartType.rawValue.lowercased())-\(timeRange.rawValue)"
    }

    /// Create cache entry for line chart data
    static func forLineChart(
        coinId: String,
        timeRange: ChartTimeRange,
        data: [ChartDataPoint]
    ) throws -> CachedChartData {
        let encoder = JSONEncoder()
        let json = try encoder.encode(data)
        let key = makeCacheKey(coinId: coinId, chartType: .line, timeRange: timeRange)
        return CachedChartData(cacheKey: key, pricesJSON: json, ttl: timeRange.cacheTTL)
    }

    /// Create cache entry for candlestick data
    static func forCandleChart(
        coinId: String,
        timeRange: ChartTimeRange,
        data: [CandleDataPoint]
    ) throws -> CachedChartData {
        let encoder = JSONEncoder()
        let json = try encoder.encode(data)
        let key = makeCacheKey(coinId: coinId, chartType: .candle, timeRange: timeRange)
        return CachedChartData(cacheKey: key, pricesJSON: json, ttl: timeRange.cacheTTL)
    }

    // MARK: - Data Retrieval

    /// Decode cached line chart data
    func decodeLineChartData() throws -> [ChartDataPoint] {
        let decoder = JSONDecoder()
        return try decoder.decode([ChartDataPoint].self, from: pricesJSON)
    }

    /// Decode cached candlestick data
    func decodeCandleChartData() throws -> [CandleDataPoint] {
        let decoder = JSONDecoder()
        return try decoder.decode([CandleDataPoint].self, from: pricesJSON)
    }
}
```

---

### ChartStatistics

Computed statistics for chart display.

```swift
import Foundation

/// Computed statistics for chart data
struct ChartStatistics {
    /// Highest price in the period
    let periodHigh: Decimal

    /// Lowest price in the period
    let periodLow: Decimal

    /// Price at the start of the period
    let startPrice: Decimal

    /// Price at the end of the period (current)
    let endPrice: Decimal

    /// Absolute price change
    var priceChange: Decimal {
        endPrice - startPrice
    }

    /// Percentage price change
    var percentageChange: Decimal {
        guard startPrice != 0 else { return 0 }
        return (priceChange / startPrice) * 100
    }

    /// True if price increased over the period
    var isPositive: Bool {
        priceChange >= 0
    }

    // MARK: - Factory Methods

    /// Calculate statistics from line chart data
    static func from(lineData: [ChartDataPoint]) -> ChartStatistics? {
        guard let first = lineData.first,
              let last = lineData.last else {
            return nil
        }

        let prices = lineData.map { $0.price }
        guard let high = prices.max(),
              let low = prices.min() else {
            return nil
        }

        return ChartStatistics(
            periodHigh: high,
            periodLow: low,
            startPrice: first.price,
            endPrice: last.price
        )
    }

    /// Calculate statistics from candlestick data
    static func from(candleData: [CandleDataPoint]) -> ChartStatistics? {
        guard let first = candleData.first,
              let last = candleData.last else {
            return nil
        }

        let highs = candleData.map { $0.high }
        let lows = candleData.map { $0.low }

        guard let high = highs.max(),
              let low = lows.min() else {
            return nil
        }

        return ChartStatistics(
            periodHigh: high,
            periodLow: low,
            startPrice: first.open,
            endPrice: last.close
        )
    }
}
```

---

## Validation Rules

### CoinDetail Validation
| Field | Rule | Error |
|-------|------|-------|
| `id` | Non-empty string | Required field |
| `symbol` | Non-empty string | Required field |
| `name` | Non-empty string | Required field |
| `currentPrice` | >= 0 | Invalid price |
| `marketCap` | nil or >= 0 | Invalid market cap |

### ChartDataPoint Validation
| Field | Rule | Error |
|-------|------|-------|
| `timestamp` | Valid date | Invalid timestamp |
| `price` | >= 0 | Invalid price |

### CandleDataPoint Validation
| Field | Rule | Error |
|-------|------|-------|
| `timestamp` | Valid date | Invalid timestamp |
| `open` | >= 0 | Invalid open price |
| `high` | >= max(open, close) | High must be highest |
| `low` | <= min(open, close) | Low must be lowest |
| `close` | >= 0 | Invalid close price |

---

## Relationships

| Entity | Related Entity | Relationship | Notes |
|--------|---------------|--------------|-------|
| CoinDetail | ChartDataPoint | 1:N | Fetched via API, not stored directly |
| CoinDetail | CandleDataPoint | 1:N | Fetched via API, not stored directly |
| ChartTimeRange | CachedChartData | N:1 | Part of cache key |
| ChartType | CachedChartData | N:1 | Part of cache key |

---

## Storage Strategy

| Entity | Storage | Rationale |
|--------|---------|-----------|
| CoinDetail | Memory only | Fetched fresh, not persisted |
| ChartDataPoint | CachedChartData | Encoded as JSON for offline |
| CandleDataPoint | CachedChartData | Encoded as JSON for offline |
| CachedChartData | Swift Data | Persistent cache with TTL |
| ChartType preference | UserDefaults | Simple key-value |

---

**Phase 1 Status**: Data Model COMPLETE
**Next**: API Contracts
