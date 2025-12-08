# Quickstart Guide: Per-Coin Price Charts

**Feature**: 007-price-charts | **Date**: 2025-12-01 | **Phase**: 1 (Design)

## Overview

This guide provides implementation patterns for the price charts feature, including code snippets that align with existing codebase conventions.

---

## 1. Service Layer Extension

### CoinGeckoService.swift Extension

Add these methods to the existing `CoinGeckoService.swift`:

```swift
// MARK: - Chart Data Endpoints

extension CoinGeckoService {

    /// Fetch coin details for header and market stats
    func fetchCoinDetail(id: String) async throws -> CoinDetail {
        await rateLimiter.waitForNextRequest()

        let urlString = "\(baseURL)/coins/\(id)?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false"

        guard let url = URL(string: urlString) else {
            throw ChartError.invalidCoinId
        }

        Logger.api.info("Fetching coin detail for \(id)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChartError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw ChartError.coinNotFound
            }
            throw ChartError.networkError(URLError(.badServerResponse))
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(CoinDetailAPIResponse.self, from: data)
        return apiResponse.toCoinDetail()
    }

    /// Fetch line chart price data
    func fetchMarketChart(
        coinId: String,
        days: String,
        currency: String = "usd"
    ) async throws -> [ChartDataPoint] {
        await rateLimiter.waitForNextRequest()

        let urlString = "\(baseURL)/coins/\(coinId)/market_chart?vs_currency=\(currency)&days=\(days)&precision=full"

        guard let url = URL(string: urlString) else {
            throw ChartError.invalidCoinId
        }

        Logger.api.info("Fetching market chart for \(coinId), days=\(days)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChartError.networkError(URLError(.badServerResponse))
        }

        let decoder = JSONDecoder()
        let chartResponse = try decoder.decode(MarketChartResponse.self, from: data)
        return chartResponse.prices.toChartDataPoints()
    }

    /// Fetch OHLC candlestick data
    func fetchOHLC(
        coinId: String,
        days: String,
        currency: String = "usd"
    ) async throws -> [CandleDataPoint] {
        await rateLimiter.waitForNextRequest()

        let urlString = "\(baseURL)/coins/\(coinId)/ohlc?vs_currency=\(currency)&days=\(days)&precision=full"

        guard let url = URL(string: urlString) else {
            throw ChartError.invalidCoinId
        }

        Logger.api.info("Fetching OHLC for \(coinId), days=\(days)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChartError.networkError(URLError(.badServerResponse))
        }

        let decoder = JSONDecoder()
        let ohlcArray = try decoder.decode([[Double]].self, from: data)
        return ohlcArray.toCandleDataPoints()
    }
}
```

### API Response Models

```swift
// MARK: - API Response Models

/// Internal response model for coin detail API
struct CoinDetailAPIResponse: Codable {
    let id: String
    let symbol: String
    let name: String
    let image: ImageURLs?
    let marketData: MarketData?
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case marketData = "market_data"
        case lastUpdated = "last_updated"
    }

    struct ImageURLs: Codable {
        let large: String?
    }

    struct MarketData: Codable {
        let currentPrice: [String: Double]?
        let priceChangePercentage24h: Double?
        let marketCap: [String: Double]?
        let totalVolume: [String: Double]?
        let circulatingSupply: Double?

        enum CodingKeys: String, CodingKey {
            case currentPrice = "current_price"
            case priceChangePercentage24h = "price_change_percentage_24h"
            case marketCap = "market_cap"
            case totalVolume = "total_volume"
            case circulatingSupply = "circulating_supply"
        }
    }

    func toCoinDetail() -> CoinDetail {
        let imageURL = image?.large.flatMap { URL(string: $0) }
        let price = Decimal(marketData?.currentPrice?["usd"] ?? 0)
        let change = Decimal(marketData?.priceChangePercentage24h ?? 0)
        let cap = marketData?.marketCap?["usd"].map { Decimal($0) }
        let volume = marketData?.totalVolume?["usd"].map { Decimal($0) }
        let supply = marketData?.circulatingSupply.map { Decimal($0) }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = lastUpdated.flatMap { formatter.date(from: $0) } ?? Date()

        return CoinDetail(
            id: id,
            symbol: symbol,
            name: name,
            image: imageURL,
            currentPrice: price,
            priceChange24h: change,
            marketCap: cap,
            totalVolume: volume,
            circulatingSupply: supply,
            lastUpdated: date
        )
    }
}

/// Market chart API response
struct MarketChartResponse: Codable {
    let prices: [[Double]]
    let marketCaps: [[Double]]?
    let totalVolumes: [[Double]]?

    enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }
}
```

---

## 2. ViewModel Implementation

### CoinDetailViewModel.swift

```swift
import Foundation
import SwiftData
import OSLog

/// ViewModel for the coin detail screen with price charts
@Observable
final class CoinDetailViewModel {

    // MARK: - Published State

    var coinDetail: CoinDetail?
    var lineChartData: [ChartDataPoint] = []
    var candleChartData: [CandleDataPoint] = []
    var chartStatistics: ChartStatistics?

    var selectedChartType: ChartType = .line {
        didSet {
            if selectedChartType != oldValue {
                selectedChartType.saveAsPreference()
                adjustTimeRangeIfNeeded()
            }
        }
    }

    var selectedTimeRange: ChartTimeRange = .oneDay

    var isLoading = false
    var isLoadingChart = false
    var errorMessage: String?

    // Touch interaction
    var selectedDataPoint: (date: Date, price: Decimal)?

    // MARK: - Dependencies

    private let coinId: String
    private let coinGeckoService: CoinGeckoService
    private var modelContext: ModelContext?

    // MARK: - Computed Properties

    var currentChartData: [ChartDataPoint] {
        lineChartData
    }

    var availableTimeRanges: [ChartTimeRange] {
        selectedChartType.availableRanges
    }

    // MARK: - Initialization

    init(
        coinId: String,
        coinGeckoService: CoinGeckoService = .shared
    ) {
        self.coinId = coinId
        self.coinGeckoService = coinGeckoService
        self.selectedChartType = ChartType.loadPreference()
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    @MainActor
    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load coin detail and chart data in parallel
            async let coinDetailTask = coinGeckoService.fetchCoinDetail(id: coinId)
            async let chartTask = loadChartData(forRange: selectedTimeRange)

            coinDetail = try await coinDetailTask
            try await chartTask

            Logger.api.info("Loaded coin detail and chart for \(self.coinId)")
        } catch {
            errorMessage = error.localizedDescription
            Logger.error.error("Failed to load coin detail: \(error)")

            // Try loading from cache
            await loadCachedData()
        }

        isLoading = false
    }

    @MainActor
    func loadChartData(forRange range: ChartTimeRange) async throws {
        isLoadingChart = true
        defer { isLoadingChart = false }

        // Check cache first
        if let cachedData = await loadFromCache(range: range) {
            applyChartData(cachedData, for: range)
            return
        }

        // Fetch from API
        switch selectedChartType {
        case .line:
            let data = try await coinGeckoService.fetchMarketChart(
                coinId: coinId,
                days: range.apiDays
            )
            let filtered = filterAndLimitData(data, for: range)
            lineChartData = filtered
            chartStatistics = ChartStatistics.from(lineData: filtered)
            await saveToCache(lineData: filtered, range: range)

        case .candle:
            let data = try await coinGeckoService.fetchOHLC(
                coinId: coinId,
                days: range.apiDays
            )
            let filtered = filterAndLimitCandleData(data, for: range)
            candleChartData = filtered
            chartStatistics = ChartStatistics.from(candleData: filtered)
            await saveToCache(candleData: filtered, range: range)
        }
    }

    @MainActor
    func switchTimeRange(to range: ChartTimeRange) async {
        guard range != selectedTimeRange else { return }

        selectedTimeRange = range

        do {
            try await loadChartData(forRange: range)
        } catch {
            errorMessage = "Failed to load chart: \(error.localizedDescription)"
        }
    }

    // MARK: - Helper Methods

    private func adjustTimeRangeIfNeeded() {
        if !selectedChartType.isRangeAvailable(selectedTimeRange) {
            selectedTimeRange = selectedChartType.closestAvailableRange(to: selectedTimeRange)
        }
    }

    private func filterAndLimitData(
        _ data: [ChartDataPoint],
        for range: ChartTimeRange
    ) -> [ChartDataPoint] {
        let filtered = range.filterDataPoints(data, timestampKeyPath: \.timestamp)
        let maxPoints = range.maxDataPoints

        guard filtered.count > maxPoints else { return filtered }

        // Downsample to maxPoints
        let step = filtered.count / maxPoints
        return stride(from: 0, to: filtered.count, by: step).map { filtered[$0] }
    }

    private func filterAndLimitCandleData(
        _ data: [CandleDataPoint],
        for range: ChartTimeRange
    ) -> [CandleDataPoint] {
        let filtered = range.filterDataPoints(data, timestampKeyPath: \.timestamp)
        let maxPoints = range.maxDataPoints

        guard filtered.count > maxPoints else { return filtered }

        let step = filtered.count / maxPoints
        return stride(from: 0, to: filtered.count, by: step).map { filtered[$0] }
    }

    private func applyChartData(_ cached: CachedChartData, for range: ChartTimeRange) {
        do {
            switch selectedChartType {
            case .line:
                lineChartData = try cached.decodeLineChartData()
                chartStatistics = ChartStatistics.from(lineData: lineChartData)
            case .candle:
                candleChartData = try cached.decodeCandleChartData()
                chartStatistics = ChartStatistics.from(candleData: candleChartData)
            }
        } catch {
            Logger.error.error("Failed to decode cached data: \(error)")
        }
    }

    // MARK: - Caching

    private func loadFromCache(range: ChartTimeRange) async -> CachedChartData? {
        guard let context = modelContext else { return nil }

        let cacheKey = CachedChartData.makeCacheKey(
            coinId: coinId,
            chartType: selectedChartType,
            timeRange: range
        )

        let predicate = #Predicate<CachedChartData> { $0.cacheKey == cacheKey }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let results = try context.fetch(descriptor)
            if let cached = results.first, !cached.isExpired {
                Logger.persistence.debug("Cache hit for \(cacheKey)")
                return cached
            }
        } catch {
            Logger.error.error("Cache fetch failed: \(error)")
        }

        return nil
    }

    private func saveToCache(lineData: [ChartDataPoint], range: ChartTimeRange) async {
        guard let context = modelContext else { return }

        do {
            let cached = try CachedChartData.forLineChart(
                coinId: coinId,
                timeRange: range,
                data: lineData
            )

            // Remove existing cache entry if any
            let cacheKey = cached.cacheKey
            let predicate = #Predicate<CachedChartData> { $0.cacheKey == cacheKey }
            try context.delete(model: CachedChartData.self, where: predicate)

            context.insert(cached)
            try context.save()

            Logger.persistence.debug("Cached line chart data for \(cacheKey)")
        } catch {
            Logger.error.error("Failed to cache data: \(error)")
        }
    }

    private func saveToCache(candleData: [CandleDataPoint], range: ChartTimeRange) async {
        guard let context = modelContext else { return }

        do {
            let cached = try CachedChartData.forCandleChart(
                coinId: coinId,
                timeRange: range,
                data: candleData
            )

            let cacheKey = cached.cacheKey
            let predicate = #Predicate<CachedChartData> { $0.cacheKey == cacheKey }
            try context.delete(model: CachedChartData.self, where: predicate)

            context.insert(cached)
            try context.save()

            Logger.persistence.debug("Cached candle chart data for \(cacheKey)")
        } catch {
            Logger.error.error("Failed to cache data: \(error)")
        }
    }

    private func loadCachedData() async {
        if let cached = await loadFromCache(range: selectedTimeRange) {
            applyChartData(cached, for: selectedTimeRange)
        }
    }
}
```

---

## 3. View Implementation

### CoinDetailView.swift

```swift
import SwiftUI

/// Main coin detail screen with header, stats, and chart
struct CoinDetailView: View {
    let coinId: String

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CoinDetailViewModel

    init(coinId: String) {
        self.coinId = coinId
        self._viewModel = State(initialValue: CoinDetailViewModel(coinId: coinId))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.standard) {
                // Coin Header
                if let coin = viewModel.coinDetail {
                    CoinHeaderView(coin: coin)
                }

                // Chart Section
                PriceChartView(viewModel: viewModel)

                // Market Stats
                if let coin = viewModel.coinDetail {
                    MarketStatsView(coin: coin)
                }
            }
            .padding(.horizontal, Spacing.medium)
        }
        .navigationTitle(viewModel.coinDetail?.name ?? "Loading...")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadInitialData()
        }
        .refreshable {
            await viewModel.loadInitialData()
        }
        .overlay {
            if viewModel.isLoading && viewModel.coinDetail == nil {
                LoadingView()
            }
        }
        .overlay(alignment: .top) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
        }
    }
}
```

### CoinHeaderView.swift

```swift
import SwiftUI

/// Header showing coin name, price, and 24h change
struct CoinHeaderView: View {
    let coin: CoinDetail

    var body: some View {
        LiquidGlassCard {
            HStack(spacing: Spacing.medium) {
                // Coin Logo
                AsyncImage(url: coin.image) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: Spacing.tiny) {
                    // Name and Symbol
                    HStack(spacing: Spacing.small) {
                        Text(coin.name)
                            .font(Typography.title2)
                            .foregroundStyle(Color.textPrimary)

                        Text(coin.symbol.uppercased())
                            .font(Typography.callout)
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Current Price
                    Text(Formatters.formatPrice(coin.currentPrice))
                        .font(Typography.largeTitle)
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                // 24h Change
                PriceChangeLabel(change: coin.priceChange24h)
            }
        }
    }
}
```

### PriceChartView.swift

```swift
import SwiftUI
import Charts

/// Chart container with type toggle and time range selector
struct PriceChartView: View {
    @Bindable var viewModel: CoinDetailViewModel

    var body: some View {
        LiquidGlassCard {
            VStack(spacing: Spacing.medium) {
                // Chart Type Toggle
                ChartTypeToggle(selectedType: $viewModel.selectedChartType)

                // Time Range Selector
                TimeRangeSelector(
                    availableRanges: viewModel.availableTimeRanges,
                    selectedRange: viewModel.selectedTimeRange
                ) { range in
                    Task {
                        await viewModel.switchTimeRange(to: range)
                    }
                }

                // Chart Statistics
                if let stats = viewModel.chartStatistics {
                    ChartStatsBar(statistics: stats)
                }

                // Chart View
                ZStack {
                    switch viewModel.selectedChartType {
                    case .line:
                        LineChartView(
                            data: viewModel.lineChartData,
                            statistics: viewModel.chartStatistics,
                            selectedPoint: $viewModel.selectedDataPoint
                        )
                    case .candle:
                        CandlestickChartView(
                            data: viewModel.candleChartData,
                            statistics: viewModel.chartStatistics,
                            selectedPoint: $viewModel.selectedDataPoint
                        )
                    }

                    if viewModel.isLoadingChart {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.1))
                    }
                }
                .frame(height: 250)

                // Selected Point Tooltip
                if let selected = viewModel.selectedDataPoint {
                    PriceTooltip(date: selected.date, price: selected.price)
                }
            }
        }
    }
}
```

### LineChartView.swift

```swift
import SwiftUI
import Charts

/// Line chart visualization
struct LineChartView: View {
    let data: [ChartDataPoint]
    let statistics: ChartStatistics?
    @Binding var selectedPoint: (date: Date, price: Decimal)?

    private var isPositive: Bool {
        statistics?.isPositive ?? true
    }

    private var lineColor: Color {
        isPositive ? .profitGreen : .lossRed
    }

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Price", point.price.doubleValue)
            )
            .foregroundStyle(lineColor)
            .interpolationMethod(.catmullRom)

            if let selected = selectedPoint, selected.date == point.timestamp {
                PointMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Price", point.price.doubleValue)
                )
                .foregroundStyle(lineColor)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.separator.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.separator.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleDrag(value: value, proxy: proxy, geometry: geometry)
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
    }

    private func handleDrag(
        value: DragGesture.Value,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        let location = value.location
        guard let date: Date = proxy.value(atX: location.x) else { return }

        // Find closest data point
        let closest = data.min { a, b in
            abs(a.timestamp.timeIntervalSince(date)) < abs(b.timestamp.timeIntervalSince(date))
        }

        if let point = closest {
            selectedPoint = (point.timestamp, point.price)
        }
    }
}

// Helper extension
extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
```

---

## 4. Navigation Integration

### Update WatchlistRowView.swift

```swift
// Add NavigationLink to CoinDetail
NavigationLink(destination: CoinDetailView(coinId: coin.id)) {
    // Existing row content
    HStack {
        // ... existing coin row layout
    }
}
```

### Update HoldingRowView.swift

```swift
// Add NavigationLink to CoinDetail
NavigationLink(destination: CoinDetailView(coinId: holding.coin.id)) {
    // Existing row content
    HStack {
        // ... existing holding row layout
    }
}
```

---

## 5. Error Handling

### ChartError.swift

```swift
import Foundation

/// Errors specific to chart operations
enum ChartError: LocalizedError {
    case invalidCoinId
    case coinNotFound
    case noHistoricalData
    case networkError(Error)
    case cacheFailed(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCoinId:
            return "Invalid cryptocurrency ID"
        case .coinNotFound:
            return "Cryptocurrency not found"
        case .noHistoricalData:
            return "No historical data available for this coin"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .cacheFailed(let error):
            return "Failed to cache data: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        }
    }
}
```

---

## 6. Testing Patterns

### ChartDataParsingTests.swift

```swift
import XCTest
@testable import Bitpal

final class ChartDataParsingTests: XCTestCase {

    func testChartDataPointFromAPI() {
        let apiArray: [Double] = [1701388800000, 42000.50]
        let point = ChartDataPoint(from: apiArray)

        XCTAssertNotNil(point)
        XCTAssertEqual(point?.price, Decimal(42000.50))
    }

    func testCandleDataPointFromAPI() {
        let apiArray: [Double] = [1701388800000, 42000, 42500, 41800, 42300]
        let candle = CandleDataPoint(from: apiArray)

        XCTAssertNotNil(candle)
        XCTAssertEqual(candle?.open, Decimal(42000))
        XCTAssertEqual(candle?.high, Decimal(42500))
        XCTAssertEqual(candle?.low, Decimal(41800))
        XCTAssertEqual(candle?.close, Decimal(42300))
        XCTAssertTrue(candle?.isGreen ?? false)
    }

    func testChartStatisticsFromLineData() {
        let data = [
            ChartDataPoint(timestamp: Date(), price: Decimal(40000)),
            ChartDataPoint(timestamp: Date(), price: Decimal(42000)),
            ChartDataPoint(timestamp: Date(), price: Decimal(41000))
        ]

        let stats = ChartStatistics.from(lineData: data)

        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.periodHigh, Decimal(42000))
        XCTAssertEqual(stats?.periodLow, Decimal(40000))
        XCTAssertEqual(stats?.startPrice, Decimal(40000))
        XCTAssertEqual(stats?.endPrice, Decimal(41000))
    }
}
```

---

## 7. File Checklist

### New Files to Create

| File | Location |
|------|----------|
| `CoinDetailView.swift` | `Features/CoinDetail/Views/` |
| `CoinHeaderView.swift` | `Features/CoinDetail/Views/` |
| `MarketStatsView.swift` | `Features/CoinDetail/Views/` |
| `PriceChartView.swift` | `Features/CoinDetail/Views/` |
| `LineChartView.swift` | `Features/CoinDetail/Views/` |
| `CandlestickChartView.swift` | `Features/CoinDetail/Views/` |
| `CoinDetailViewModel.swift` | `Features/CoinDetail/ViewModels/` |
| `CoinDetail.swift` | `Features/CoinDetail/Models/` |
| `ChartDataPoint.swift` | `Features/CoinDetail/Models/` |
| `CandleDataPoint.swift` | `Features/CoinDetail/Models/` |
| `ChartTimeRange.swift` | `Features/CoinDetail/Models/` |
| `ChartType.swift` | `Features/CoinDetail/Models/` |
| `ChartStatistics.swift` | `Features/CoinDetail/Models/` |
| `ChartError.swift` | `Features/CoinDetail/Models/` |
| `CachedChartData.swift` | `Features/CoinDetail/Models/` |
| `TimeRangeSelector.swift` | `Design/Components/ChartComponents/` |
| `ChartTypeToggle.swift` | `Design/Components/ChartComponents/` |
| `PriceTooltip.swift` | `Design/Components/ChartComponents/` |
| `ChartDataParsingTests.swift` | `BitpalTests/CoinDetailTests/` |
| `CoinDetailViewModelTests.swift` | `BitpalTests/CoinDetailTests/` |

### Files to Modify

| File | Changes |
|------|---------|
| `CoinGeckoService.swift` | Add chart data methods |
| `WatchlistRowView.swift` | Add NavigationLink to CoinDetail |
| `HoldingRowView.swift` | Add NavigationLink to CoinDetail |
| `BitpalApp.swift` | Register CachedChartData model |

---

**Phase 1 Status**: Quickstart COMPLETE
**Next Step**: Run `/speckit.tasks` to generate implementation tasks
