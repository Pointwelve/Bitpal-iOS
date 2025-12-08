//
//  CoinDetailViewModel.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel for the coin detail screen
/// Per Constitution Principle III: Uses @Observable (NOT ObservableObject)
@Observable
@MainActor
final class CoinDetailViewModel {
    // MARK: - Properties

    /// CoinGecko ID for the coin being displayed
    let coinId: String

    /// Detailed coin information (price, market cap, etc.)
    var coinDetail: CoinDetail?

    /// Line chart data points for the selected time range
    var lineChartData: [ChartDataPoint] = []

    /// Candlestick data points for the selected time range
    var candleChartData: [CandleDataPoint] = []

    /// Statistics calculated from chart data
    var chartStatistics: ChartStatistics?

    /// Currently selected chart type (line or candle)
    var selectedChartType: ChartType = .line {
        didSet {
            if oldValue != selectedChartType {
                selectedChartType.saveAsPreference()
                adjustTimeRangeIfNeeded()
            }
        }
    }

    /// Currently selected time range
    var selectedTimeRange: ChartTimeRange = .oneDay

    /// Available time ranges based on current chart type
    var availableTimeRanges: [ChartTimeRange] {
        selectedChartType.availableRanges
    }

    /// Loading state for initial data fetch
    var isLoading = false

    /// Loading state for chart data (during time range switch)
    var isLoadingChart = false

    /// Error message to display
    var errorMessage: String?

    /// Indicates if the chart data has limited history (less than requested range)
    var hasLimitedHistory = false

    /// Reference to the Swift Data model context for caching
    private var modelContext: ModelContext?

    // MARK: - Initialization

    init(coinId: String) {
        self.coinId = coinId
        // Load saved chart type preference
        self.selectedChartType = ChartType.loadPreference()
    }

    // MARK: - Configuration

    /// Configure with Swift Data model context for caching
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Load initial data: coin detail and chart for current type
    @MainActor
    func loadInitialData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Logger.chart.info("CoinDetailViewModel: Loading initial data for \(self.coinId)")

        do {
            // Fetch coin detail first, then chart data
            coinDetail = try await CoinGeckoService.shared.fetchCoinDetail(id: coinId)

            // Load chart data based on saved chart type preference
            switch selectedChartType {
            case .line:
                try await loadLineChartData(forRange: selectedTimeRange)
            case .candle:
                try await loadCandleChartData(forRange: selectedTimeRange)
            }

            Logger.chart.info("CoinDetailViewModel: Initial data loaded for \(self.coinId)")
        } catch {
            Logger.chart.error("CoinDetailViewModel: Failed to load initial data - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load chart data for a specific time range (dispatches to line or candle)
    @MainActor
    func loadChartData(forRange range: ChartTimeRange) async throws {
        switch selectedChartType {
        case .line:
            try await loadLineChartData(forRange: range)
        case .candle:
            try await loadCandleChartData(forRange: range)
        }
    }

    /// Load line chart data for a specific time range
    @MainActor
    func loadLineChartData(forRange range: ChartTimeRange) async throws {
        isLoadingChart = true
        selectedTimeRange = range
        hasLimitedHistory = false

        Logger.chart.info("CoinDetailViewModel: Loading line chart data for range \(range.rawValue)")

        // Check cache first
        if let cached = loadLineFromCache(range: range) {
            lineChartData = cached
            chartStatistics = ChartStatistics.from(lineData: cached)
            hasLimitedHistory = checkLimitedHistory(data: cached, range: range)
            isLoadingChart = false
            Logger.chart.debug("CoinDetailViewModel: Loaded line data from cache")
            return
        }

        do {
            // Fetch from API
            let data = try await CoinGeckoService.shared.fetchMarketChart(
                coinId: coinId,
                days: range.apiDays
            )

            // Filter and limit data points for selected range
            let filteredData = filterAndLimitLineData(data, forRange: range)

            lineChartData = filteredData
            chartStatistics = ChartStatistics.from(lineData: filteredData)
            hasLimitedHistory = checkLimitedHistory(data: filteredData, range: range)

            // Save to cache
            saveLineToCache(lineData: filteredData, range: range)

            Logger.chart.info("CoinDetailViewModel: Line chart data loaded - \(filteredData.count) points")
        } catch {
            Logger.chart.error("CoinDetailViewModel: Failed to load line chart data - \(error.localizedDescription)")
            throw error
        }

        isLoadingChart = false
    }

    /// Load candlestick chart data for a specific time range
    @MainActor
    func loadCandleChartData(forRange range: ChartTimeRange) async throws {
        isLoadingChart = true
        selectedTimeRange = range
        hasLimitedHistory = false

        Logger.chart.info("CoinDetailViewModel: Loading candle chart data for range \(range.rawValue)")

        // Check cache first
        if let cached = loadCandleFromCache(range: range) {
            candleChartData = cached
            chartStatistics = ChartStatistics.from(candleData: cached)
            hasLimitedHistory = checkLimitedHistory(candleData: cached, range: range)
            isLoadingChart = false
            Logger.chart.debug("CoinDetailViewModel: Loaded candle data from cache")
            return
        }

        do {
            // Fetch from API
            let data = try await CoinGeckoService.shared.fetchOHLC(
                coinId: coinId,
                days: range.apiDays
            )

            // Filter and limit data points for selected range
            let filteredData = filterAndLimitCandleData(data, forRange: range)

            candleChartData = filteredData
            chartStatistics = ChartStatistics.from(candleData: filteredData)
            hasLimitedHistory = checkLimitedHistory(candleData: filteredData, range: range)

            // Save to cache
            saveCandleToCache(candleData: filteredData, range: range)

            Logger.chart.info("CoinDetailViewModel: Candle chart data loaded - \(filteredData.count) candles")
        } catch {
            Logger.chart.error("CoinDetailViewModel: Failed to load candle chart data - \(error.localizedDescription)")
            throw error
        }

        isLoadingChart = false
    }

    /// Refresh all data (pull-to-refresh)
    @MainActor
    func refresh() async {
        Logger.chart.info("CoinDetailViewModel: Refreshing data")

        do {
            coinDetail = try await CoinGeckoService.shared.fetchCoinDetail(id: coinId)
            try await loadChartData(forRange: selectedTimeRange)
        } catch {
            Logger.chart.error("CoinDetailViewModel: Refresh failed - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Switch to a different time range
    @MainActor
    func switchTimeRange(to range: ChartTimeRange) {
        Logger.chart.info("CoinDetailViewModel: Switching to time range \(range.rawValue)")

        // Set loading BEFORE starting async load to prevent placeholder flash
        isLoadingChart = true

        Task {
            do {
                try await loadChartData(forRange: range)
            } catch {
                Logger.chart.error("CoinDetailViewModel: Time range switch failed - \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                isLoadingChart = false
            }
        }
    }

    /// Switch to a different chart type
    @MainActor
    func switchChartType(to type: ChartType) {
        guard type != selectedChartType else { return }

        Logger.chart.info("CoinDetailViewModel: Switching to chart type \(type.rawValue)")

        // Set loading BEFORE changing chart type to prevent placeholder flash
        isLoadingChart = true

        selectedChartType = type
        // Note: adjustTimeRangeIfNeeded() is called by the didSet observer

        // Reload chart data for new type
        Task {
            do {
                try await loadChartData(forRange: selectedTimeRange)
            } catch {
                Logger.chart.error("CoinDetailViewModel: Chart type switch failed - \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                isLoadingChart = false
            }
        }
    }

    /// Adjust time range when switching chart types if current range isn't available
    private func adjustTimeRangeIfNeeded() {
        if !selectedChartType.isRangeAvailable(selectedTimeRange) {
            selectedTimeRange = selectedChartType.closestAvailableRange(to: selectedTimeRange)
            Logger.chart.info("CoinDetailViewModel: Adjusted time range to \(self.selectedTimeRange.rawValue)")
        }
    }

    // MARK: - Limited History Detection

    /// Check if line chart data covers less than the expected time range
    /// This happens for newly listed coins or coins with limited trading history
    private func checkLimitedHistory(data: [ChartDataPoint], range: ChartTimeRange) -> Bool {
        guard let oldest = data.first?.timestamp, let newest = data.last?.timestamp else {
            return false
        }

        let actualSpan = newest.timeIntervalSince(oldest)
        let expectedSpan = range.expectedTimeSpan

        // Consider it limited if we have less than 80% of the expected time span
        return actualSpan < (expectedSpan * 0.8)
    }

    /// Check if candle chart data covers less than the expected time range
    private func checkLimitedHistory(candleData: [CandleDataPoint], range: ChartTimeRange) -> Bool {
        guard let oldest = candleData.first?.timestamp, let newest = candleData.last?.timestamp else {
            return false
        }

        let actualSpan = newest.timeIntervalSince(oldest)
        let expectedSpan = range.expectedTimeSpan

        // Consider it limited if we have less than 80% of the expected time span
        return actualSpan < (expectedSpan * 0.8)
    }

    // MARK: - Data Filtering

    /// Filter line chart data points to match time range and limit count for performance
    private func filterAndLimitLineData(_ data: [ChartDataPoint], forRange range: ChartTimeRange) -> [ChartDataPoint] {
        // Filter to selected time range
        let filtered = range.filterDataPoints(data, timestampKeyPath: \.timestamp)

        // Limit to max data points for performance
        let maxPoints = range.maxDataPoints
        guard filtered.count > maxPoints else { return filtered }

        // Downsample by taking evenly spaced points
        let step = filtered.count / maxPoints
        return stride(from: 0, to: filtered.count, by: step).map { filtered[$0] }
    }

    /// Filter candle chart data points to match time range and limit count for performance
    private func filterAndLimitCandleData(_ data: [CandleDataPoint], forRange range: ChartTimeRange) -> [CandleDataPoint] {
        // Filter to selected time range
        let filtered = range.filterDataPoints(data, timestampKeyPath: \.timestamp)

        // Use consistent candle count (42) for uniform visual density across all time ranges
        let maxPoints = ChartTimeRange.candleMaxDataPoints
        let limited: [CandleDataPoint]
        if filtered.count > maxPoints {
            // Downsample by taking evenly spaced candles
            let step = filtered.count / maxPoints
            limited = stride(from: 0, to: filtered.count, by: step).map { filtered[$0] }
        } else {
            limited = filtered
        }

        // Ensure candle continuity (each candle's open = previous candle's close)
        // This fixes visual gaps caused by CoinGecko API returning non-continuous OHLC data
        return limited.ensureContinuity()
    }

    // MARK: - Caching

    /// Load line chart data from Swift Data cache
    private func loadLineFromCache(range: ChartTimeRange) -> [ChartDataPoint]? {
        guard let context = modelContext else { return nil }

        let cacheKey = CachedChartData.makeCacheKey(
            coinId: coinId,
            chartType: .line,
            timeRange: range
        )

        let predicate = #Predicate<CachedChartData> { $0.cacheKey == cacheKey }
        let descriptor = FetchDescriptor<CachedChartData>(predicate: predicate)

        do {
            let results = try context.fetch(descriptor)
            guard let cached = results.first, !cached.isExpired else {
                return nil
            }

            return try cached.decodeLineChartData()
        } catch {
            Logger.chart.warning("CoinDetailViewModel: Line cache read failed - \(error.localizedDescription)")
            return nil
        }
    }

    /// Load candle chart data from Swift Data cache
    private func loadCandleFromCache(range: ChartTimeRange) -> [CandleDataPoint]? {
        guard let context = modelContext else { return nil }

        let cacheKey = CachedChartData.makeCacheKey(
            coinId: coinId,
            chartType: .candle,
            timeRange: range
        )

        let predicate = #Predicate<CachedChartData> { $0.cacheKey == cacheKey }
        let descriptor = FetchDescriptor<CachedChartData>(predicate: predicate)

        do {
            let results = try context.fetch(descriptor)
            guard let cached = results.first, !cached.isExpired else {
                return nil
            }

            return try cached.decodeCandleChartData()
        } catch {
            Logger.chart.warning("CoinDetailViewModel: Candle cache read failed - \(error.localizedDescription)")
            return nil
        }
    }

    /// Save line chart data to Swift Data cache
    private func saveLineToCache(lineData: [ChartDataPoint], range: ChartTimeRange) {
        guard let context = modelContext else { return }

        do {
            let cached = try CachedChartData.forLineChart(
                coinId: coinId,
                timeRange: range,
                data: lineData
            )

            // Delete existing cache entry if present
            let cacheKey = cached.cacheKey
            let predicate = #Predicate<CachedChartData> { $0.cacheKey == cacheKey }
            let descriptor = FetchDescriptor<CachedChartData>(predicate: predicate)

            let existing = try context.fetch(descriptor)
            for old in existing {
                context.delete(old)
            }

            context.insert(cached)
            try context.save()

            Logger.chart.debug("CoinDetailViewModel: Saved line data to cache - \(cacheKey)")
        } catch {
            Logger.chart.warning("CoinDetailViewModel: Line cache write failed - \(error.localizedDescription)")
        }
    }

    /// Save candle chart data to Swift Data cache
    private func saveCandleToCache(candleData: [CandleDataPoint], range: ChartTimeRange) {
        guard let context = modelContext else { return }

        do {
            let cached = try CachedChartData.forCandleChart(
                coinId: coinId,
                timeRange: range,
                data: candleData
            )

            // Delete existing cache entry if present
            let cacheKey = cached.cacheKey
            let predicate = #Predicate<CachedChartData> { $0.cacheKey == cacheKey }
            let descriptor = FetchDescriptor<CachedChartData>(predicate: predicate)

            let existing = try context.fetch(descriptor)
            for old in existing {
                context.delete(old)
            }

            context.insert(cached)
            try context.save()

            Logger.chart.debug("CoinDetailViewModel: Saved candle data to cache - \(cacheKey)")
        } catch {
            Logger.chart.warning("CoinDetailViewModel: Candle cache write failed - \(error.localizedDescription)")
        }
    }
}
