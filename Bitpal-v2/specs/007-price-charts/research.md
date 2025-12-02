# Research: Per-Coin Price Charts

**Feature**: 007-price-charts | **Date**: 2025-12-01 | **Phase**: 0 (Research)

## Executive Summary

This document captures technical research for implementing per-coin price charts with line and candlestick visualizations. Key findings: Swift Charts (native) supports both chart types through composition, CoinGecko provides both `/market_chart` and `/ohlc` endpoints with auto-granularity, and existing codebase patterns provide clear implementation guidance.

---

## 1. Swift Charts Framework Analysis

### 1.1 Framework Overview

Apple's Swift Charts (iOS 16+) is the native charting framework for SwiftUI. It provides:

- **Built-in mark types**: `LineMark`, `PointMark`, `BarMark`, `RectangleMark`, `AreaMark`, `RuleMark`
- **ChartContent protocol**: Enables custom mark composition
- **Time series support**: Native `Date` handling on axes
- **Gesture support**: Built-in selection and hover interactions

**Sources**:
- [Swift Charts Documentation](https://developer.apple.com/documentation/Charts)
- [Creating a chart using Swift Charts](https://developer.apple.com/documentation/charts/creating-a-chart-using-swift-charts)

### 1.2 Line Chart Implementation

Line charts use `LineMark` with optional `PointMark` overlay:

```swift
import Charts

struct PriceLineChart: View {
    let data: [ChartDataPoint]

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Price", point.price)
            )
            .foregroundStyle(priceChangeColor)
            .interpolationMethod(.catmullRom) // Smooth curves
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
        .chartYAxis {
            AxisMarks(position: .trailing)
        }
    }
}
```

**Key considerations**:
- Use `.interpolationMethod(.catmullRom)` for smooth financial curves
- Limit data points to ~100 for 60fps performance
- Use `Date` type for X-axis with time series data

### 1.3 Candlestick Chart Implementation

Swift Charts doesn't provide native candlestick marks, but they can be composed using `RectangleMark`:

```swift
struct CandlestickMark<X: Plottable>: ChartContent {
    let x: PlottableValue<X>
    let open: PlottableValue<Decimal>
    let high: PlottableValue<Decimal>
    let low: PlottableValue<Decimal>
    let close: PlottableValue<Decimal>
    let isGreen: Bool

    var body: some ChartContent {
        // Wick (thin line from low to high)
        RectangleMark(
            x: x,
            yStart: low,
            yEnd: high,
            width: 2
        )
        .foregroundStyle(isGreen ? Color.profitGreen : Color.lossRed)

        // Body (thicker rectangle from open to close)
        RectangleMark(
            x: x,
            yStart: open,
            yEnd: close,
            width: 8
        )
        .foregroundStyle(isGreen ? Color.profitGreen : Color.lossRed)
    }
}
```

**Source**: [Mastering Charts in SwiftUI - Custom Marks](https://swiftwithmajid.com/2023/01/26/mastering-charts-in-swiftui-custom-marks/)

### 1.4 Touch Interaction for Price Inspection

Swift Charts supports chart selection via `chartOverlay`:

```swift
Chart(data) { ... }
    .chartOverlay { proxy in
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let location = value.location
                            if let date: Date = proxy.value(atX: location.x),
                               let price: Decimal = proxy.value(atY: location.y) {
                                selectedPoint = (date, price)
                            }
                        }
                        .onEnded { _ in
                            selectedPoint = nil
                        }
                )
        }
    }
```

**Performance note**: Use `@State` for selection tracking to ensure 60fps updates.

### 1.5 Chart Styling for Liquid Glass

```swift
Chart { ... }
    .chartBackground { _ in
        Color.clear // Transparent for glass effect
    }
    .chartPlotStyle { plotArea in
        plotArea
            .background(.ultraThinMaterial.opacity(0.3))
            .cornerRadius(12)
    }
    .chartXAxis {
        AxisMarks { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(Color.separator.opacity(0.5))
            AxisValueLabel()
                .foregroundStyle(Color.textSecondary)
        }
    }
```

---

## 2. CoinGecko API Analysis

### 2.1 Market Chart Endpoint (Line Charts)

**Endpoint**: `GET /coins/{id}/market_chart`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Coin ID (e.g., "bitcoin") |
| `vs_currency` | string | Yes | Target currency (e.g., "usd") |
| `days` | string | Yes | Data span: "1", "7", "14", "30", "90", "180", "365", "max" |
| `interval` | string | No | Granularity: "5m", "hourly", "daily" |
| `precision` | string | No | Decimal places: "full", "0"-"18" |

**Auto-Granularity Rules** (when `interval` omitted):
| Days | Granularity | Data Points |
|------|-------------|-------------|
| 1 | 5-minute | ~288 |
| 2-90 | Hourly | 48-2160 |
| 90+ | Daily | ~365 |

**Response Format**:
```json
{
  "prices": [
    [1701388800000, 42000.50],
    [1701392400000, 42150.75]
  ],
  "market_caps": [...],
  "total_volumes": [...]
}
```

**Note**: Timestamps are Unix milliseconds. Cache refreshes every 30 seconds.

### 2.2 OHLC Endpoint (Candlestick Charts)

**Endpoint**: `GET /coins/{id}/ohlc`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | Yes | Coin ID |
| `vs_currency` | string | Yes | Target currency |
| `days` | enum | Yes | "1", "7", "14", "30", "90", "180", "365", "max" |
| `interval` | string | No | "daily", "hourly" |
| `precision` | string | No | Decimal places |

**Auto-Granularity Rules** (candle body size):
| Days | Candle Interval |
|------|-----------------|
| 1-2 | 30 minutes |
| 3-30 | 4 hours |
| 31+ | 4 days |

**Response Format**:
```json
[
  [1701388800000, 42000, 42500, 41800, 42300],
  [1701392400000, 42300, 42600, 42100, 42450]
]
```

Array structure: `[timestamp, open, high, low, close]`

**Note**: Cache updates every 15 minutes. Previous UTC day available at 00:35 UTC.

### 2.3 Rate Limits

- **Free tier**: 50 calls/minute (~10,000-30,000/month)
- **Minimum interval**: 1.2 seconds between requests
- **Existing implementation**: `RateLimiter.swift` already handles this

### 2.4 API Mapping to Time Ranges

**Line Chart Time Ranges**:
| UI Range | API `days` | Expected Points | Cache TTL |
|----------|------------|-----------------|-----------|
| 1H | 1 | ~12 (5-min) | 1 min |
| 1D | 1 | ~288 (5-min) | 5 min |
| 1W | 7 | ~168 (hourly) | 15 min |
| 1M | 30 | ~720 (hourly) | 30 min |
| 1Y | 365 | ~365 (daily) | 1 hour |

**Candlestick Time Ranges**:
| UI Range | API `days` | Candle Interval | Cache TTL |
|----------|------------|-----------------|-----------|
| 15M | 1 | 30-min (trim to 15M) | 1 min |
| 1H | 1 | 30-min (trim to 1H) | 1 min |
| 4H | 1 | 30-min (trim to 4H) | 1 min |
| 1D | 1 | 30-min | 5 min |
| 1W | 7 | 4-hour | 15 min |
| 1M | 30 | 4-hour | 30 min |
| 1Y | 365 | 4-day | 1 hour |

---

## 3. Existing Codebase Patterns

### 3.1 Service Layer Pattern

From `CoinGeckoService.swift`:

```swift
// Singleton with rate limiting
static let shared = CoinGeckoService()
private let rateLimiter = RateLimiter()

func fetchPrices(coinIds: [String]) async throws -> [String: Coin] {
    await rateLimiter.waitForNextRequest()

    let ids = coinIds.joined(separator: ",")
    let url = URL(string: "\(baseURL)/simple/price?ids=\(ids)&vs_currencies=usd")!

    let (data, response) = try await session.data(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw APIError.invalidResponse
    }

    return try JSONDecoder().decode([String: PriceData].self, from: data)
}
```

**Key patterns**:
- Rate limiting before every request
- Status code validation
- Custom error types
- JSON decoding with custom strategies

### 3.2 Caching Strategy

Current implementation uses in-memory caching with TTL:

```swift
private var cachedMarketData: [String: Coin] = [:]
private var marketDataCacheTime: Date?
private let marketDataCacheTTL: TimeInterval = 30

func isCacheValid() -> Bool {
    guard let cacheTime = marketDataCacheTime else { return false }
    return Date().timeIntervalSince(cacheTime) < marketDataCacheTTL
}
```

**For charts**: Implement similar pattern with longer TTLs based on time range.

### 3.3 ViewModel Pattern

From `WatchlistViewModel.swift`:

```swift
@Observable
final class WatchlistViewModel {
    var watchlistCoins: [(WatchlistItem, Coin)] = []
    var isLoading = false
    var errorMessage: String?

    private var coinGeckoService: CoinGeckoService

    init(coinGeckoService: CoinGeckoService = .shared) {
        self.coinGeckoService = coinGeckoService
    }

    @MainActor
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch and update state
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### 3.4 View Navigation Pattern

From `WatchlistView.swift` and `HoldingRowView.swift`:

```swift
// Current pattern: NavigationLink for drill-down
NavigationLink(destination: TransactionHistoryView(holding: holding)) {
    HoldingRowView(holding: holding)
}

// For CoinDetail: Same pattern
NavigationLink(destination: CoinDetailView(coinId: coin.id)) {
    CoinRowView(coin: coin)
}
```

### 3.5 Design System Usage

```swift
// Colors
Color.profitGreen  // Positive price movement
Color.lossRed      // Negative price movement
Color.textPrimary  // Primary text
Color.textSecondary // Secondary labels

// Spacing
Spacing.standard   // 12pt (default card spacing)
Spacing.medium     // 16pt (section padding)
Spacing.cornerRadius // 16pt (cards)

// Typography
Typography.priceDisplay // .headline.monospacedDigit()

// Components
LiquidGlassCard { content }  // Glassmorphism container
PriceChangeLabel(change: value)  // Color-coded percentage
```

---

## 4. Data Model Design

### 4.1 Chart Data Models

```swift
/// Line chart data point
struct ChartDataPoint: Identifiable, Codable, Equatable {
    var id: Date { timestamp }
    let timestamp: Date
    let price: Decimal
}

/// Candlestick OHLC data point
struct CandleDataPoint: Identifiable, Codable, Equatable {
    var id: Date { timestamp }
    let timestamp: Date
    let open: Decimal
    let high: Decimal
    let low: Decimal
    let close: Decimal

    var isGreen: Bool { close >= open }
}

/// Time range options
enum ChartTimeRange: String, CaseIterable, Identifiable {
    case fifteenMinutes = "15M"
    case oneHour = "1H"
    case fourHours = "4H"
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case oneYear = "1Y"

    var id: String { rawValue }

    var apiDays: String {
        switch self {
        case .fifteenMinutes, .oneHour, .fourHours, .oneDay: return "1"
        case .oneWeek: return "7"
        case .oneMonth: return "30"
        case .oneYear: return "365"
        }
    }

    var cacheTTL: TimeInterval {
        switch self {
        case .fifteenMinutes, .oneHour, .fourHours: return 60  // 1 min
        case .oneDay: return 300  // 5 min
        case .oneWeek: return 900  // 15 min
        case .oneMonth: return 1800 // 30 min
        case .oneYear: return 3600 // 1 hour
        }
    }

    /// Available ranges per chart type
    static var lineRanges: [ChartTimeRange] {
        [.oneHour, .oneDay, .oneWeek, .oneMonth, .oneYear]
    }

    static var candleRanges: [ChartTimeRange] {
        [.fifteenMinutes, .oneHour, .fourHours, .oneDay, .oneWeek, .oneMonth, .oneYear]
    }
}

/// Chart type selection
enum ChartType: String, CaseIterable, Identifiable {
    case line = "Line"
    case candle = "Candle"

    var id: String { rawValue }

    var availableRanges: [ChartTimeRange] {
        switch self {
        case .line: return ChartTimeRange.lineRanges
        case .candle: return ChartTimeRange.candleRanges
        }
    }
}
```

### 4.2 API Response Models

```swift
/// CoinGecko market_chart response
struct MarketChartResponse: Codable {
    let prices: [[Double]]  // [[timestamp, price], ...]
    let marketCaps: [[Double]]?
    let totalVolumes: [[Double]]?

    enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }

    func toChartDataPoints() -> [ChartDataPoint] {
        prices.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            let timestamp = Date(timeIntervalSince1970: pair[0] / 1000)
            let price = Decimal(pair[1])
            return ChartDataPoint(timestamp: timestamp, price: price)
        }
    }
}

/// CoinGecko OHLC response (array of arrays)
typealias OHLCResponse = [[Double]]  // [[timestamp, open, high, low, close], ...]

extension Array where Element == [Double] {
    func toCandleDataPoints() -> [CandleDataPoint] {
        compactMap { candle in
            guard candle.count >= 5 else { return nil }
            return CandleDataPoint(
                timestamp: Date(timeIntervalSince1970: candle[0] / 1000),
                open: Decimal(candle[1]),
                high: Decimal(candle[2]),
                low: Decimal(candle[3]),
                close: Decimal(candle[4])
            )
        }
    }
}
```

### 4.3 Cache Model (Swift Data)

```swift
import SwiftData

@Model
final class CachedChartData {
    @Attribute(.unique) var cacheKey: String  // "bitcoin-line-1D"
    var pricesJSON: Data  // Encoded [ChartDataPoint] or [CandleDataPoint]
    var cachedAt: Date
    var expiresAt: Date

    init(cacheKey: String, pricesJSON: Data, ttl: TimeInterval) {
        self.cacheKey = cacheKey
        self.pricesJSON = pricesJSON
        self.cachedAt = Date()
        self.expiresAt = Date().addingTimeInterval(ttl)
    }

    var isExpired: Bool {
        Date() > expiresAt
    }
}
```

---

## 5. Performance Considerations

### 5.1 Data Point Limits

| Time Range | Max Points | Rationale |
|------------|------------|-----------|
| 15M | 15 | 1-min candles |
| 1H | 60 | 1-min data |
| 4H | 48 | 5-min candles |
| 1D | 96 | 15-min intervals (trimmed from 5-min) |
| 1W | 42 | 4-hour intervals |
| 1M | 30 | Daily intervals |
| 1Y | 52 | Weekly intervals |

**Rationale**: Keep under 100 points per view for 60fps performance.

### 5.2 Memory Management

- **Chart data**: Store as lightweight structs
- **Cache**: Use Swift Data with automatic cleanup of expired entries
- **Images**: Coin logos already cached by existing service

### 5.3 Animation Performance

```swift
// Use explicit animations with reasonable duration
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTimeRange)

// Avoid animating data changes directly
.animation(nil, value: chartData)
```

---

## 6. Risk Assessment

### 6.1 Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Candlestick performance | Medium | Limit to 60 candles max, use `RectangleMark` composition |
| API rate limits | Low | Existing `RateLimiter` handles this |
| Offline support | Medium | Swift Data cache with appropriate TTLs |
| Touch interaction lag | High | Use `@State` for selection, avoid heavy recomputation |

### 6.2 API Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| API unavailable | Medium | Show cached data with "Last updated" indicator |
| Response format change | Low | Defensive parsing with optional fields |
| New coin without history | Low | Display "Limited data available" message |

---

## 7. Implementation Recommendations

### 7.1 Phased Approach

1. **Phase A**: Basic line chart with 1D default
2. **Phase B**: Time range selector (all 5 line ranges)
3. **Phase C**: Candlestick chart type toggle
4. **Phase D**: Touch interaction for price inspection
5. **Phase E**: Coin header and market stats integration
6. **Phase F**: Caching and offline support

### 7.2 Key Decisions

| Decision | Recommendation | Rationale |
|----------|---------------|-----------|
| Charting library | Swift Charts (native) | No external dependencies (Constitution III) |
| Data persistence | Swift Data | Consistent with existing patterns |
| Chart type preference | UserDefaults | Simple key-value, no model needed |
| Decimal handling | Custom Decodable | API returns Double, convert to Decimal |

### 7.3 File Structure

```
Features/CoinDetail/
├── Views/
│   ├── CoinDetailView.swift        # Main container
│   ├── CoinHeaderView.swift        # Name, price, 24h change
│   ├── MarketStatsView.swift       # Market cap, volume, supply
│   ├── PriceChartView.swift        # Chart container with controls
│   ├── LineChartView.swift         # Line chart rendering
│   └── CandlestickChartView.swift  # Candlestick rendering
├── ViewModels/
│   └── CoinDetailViewModel.swift   # @Observable state management
└── Models/
    ├── ChartDataPoint.swift        # Line chart data
    ├── CandleDataPoint.swift       # OHLC data
    ├── ChartTimeRange.swift        # Time range enum
    └── ChartType.swift             # Chart type enum
```

---

## 8. References

### External Documentation
- [Swift Charts | Apple Developer Documentation](https://developer.apple.com/documentation/Charts)
- [Creating a chart using Swift Charts](https://developer.apple.com/documentation/charts/creating-a-chart-using-swift-charts)
- [Mastering Charts in SwiftUI - Custom Marks](https://swiftwithmajid.com/2023/01/26/mastering-charts-in-swiftui-custom-marks/)
- [CoinGecko API - Market Chart](https://docs.coingecko.com/reference/coins-id-market-chart)
- [CoinGecko API - OHLC](https://docs.coingecko.com/reference/coins-id-ohlc)

### Internal References
- `Bitpal/Services/CoinGeckoService.swift` - API patterns
- `Bitpal/Services/RateLimiter.swift` - Rate limiting
- `Bitpal/Features/Watchlist/ViewModels/WatchlistViewModel.swift` - ViewModel patterns
- `Bitpal/Design/Styles/` - Design system (Colors, Spacing, Typography)

---

**Phase 0 Status**: COMPLETE
**Next Phase**: Phase 1 (Data Model & Contracts)
