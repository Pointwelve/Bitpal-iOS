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
final class CoinDetailViewModel {
    // MARK: - Properties

    /// CoinGecko ID for the coin being displayed
    let coinId: String

    /// Detailed coin information (price, market cap, etc.)
    var coinDetail: CoinDetail?

    /// Line chart data points for the selected time range
    var lineChartData: [ChartDataPoint] = []

    /// Statistics calculated from chart data
    var chartStatistics: ChartStatistics?

    /// Currently selected time range
    var selectedTimeRange: ChartTimeRange = .oneDay

    /// Loading state for initial data fetch
    var isLoading = false

    /// Loading state for chart data (during time range switch)
    var isLoadingChart = false

    /// Error message to display
    var errorMessage: String?

    /// Reference to the Swift Data model context for caching
    private var modelContext: ModelContext?

    // MARK: - Initialization

    init(coinId: String) {
        self.coinId = coinId
    }

    // MARK: - Configuration

    /// Configure with Swift Data model context for caching
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Load initial data: coin detail and 1D chart
    @MainActor
    func loadInitialData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Logger.chart.info("CoinDetailViewModel: Loading initial data for \(self.coinId)")

        do {
            // Fetch coin detail first, then chart data
            coinDetail = try await CoinGeckoService.shared.fetchCoinDetail(id: coinId)
            try await loadChartData(forRange: .oneDay)

            Logger.chart.info("CoinDetailViewModel: Initial data loaded for \(self.coinId)")
        } catch {
            Logger.chart.error("CoinDetailViewModel: Failed to load initial data - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load chart data for a specific time range
    @MainActor
    func loadChartData(forRange range: ChartTimeRange) async throws {
        isLoadingChart = true
        selectedTimeRange = range

        Logger.chart.info("CoinDetailViewModel: Loading chart data for range \(range.rawValue)")

        // Check cache first
        if let cached = loadFromCache(range: range) {
            lineChartData = cached
            chartStatistics = ChartStatistics.from(lineData: cached)
            isLoadingChart = false
            Logger.chart.debug("CoinDetailViewModel: Loaded from cache")
            return
        }

        do {
            // Fetch from API
            let data = try await CoinGeckoService.shared.fetchMarketChart(
                coinId: coinId,
                days: range.apiDays
            )

            // Filter and limit data points for selected range
            let filteredData = filterAndLimitData(data, forRange: range)

            lineChartData = filteredData
            chartStatistics = ChartStatistics.from(lineData: filteredData)

            // Save to cache
            saveToCache(lineData: filteredData, range: range)

            Logger.chart.info("CoinDetailViewModel: Chart data loaded - \(filteredData.count) points")
        } catch {
            Logger.chart.error("CoinDetailViewModel: Failed to load chart data - \(error.localizedDescription)")
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

        Task {
            do {
                try await loadChartData(forRange: range)
            } catch {
                Logger.chart.error("CoinDetailViewModel: Time range switch failed - \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Data Filtering

    /// Filter data points to match time range and limit count for performance
    private func filterAndLimitData(_ data: [ChartDataPoint], forRange range: ChartTimeRange) -> [ChartDataPoint] {
        // Filter to selected time range
        let filtered = range.filterDataPoints(data, timestampKeyPath: \.timestamp)

        // Limit to max data points for performance
        let maxPoints = range.maxDataPoints
        guard filtered.count > maxPoints else { return filtered }

        // Downsample by taking evenly spaced points
        let step = filtered.count / maxPoints
        return stride(from: 0, to: filtered.count, by: step).map { filtered[$0] }
    }

    // MARK: - Caching

    /// Load chart data from Swift Data cache
    private func loadFromCache(range: ChartTimeRange) -> [ChartDataPoint]? {
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
            Logger.chart.warning("CoinDetailViewModel: Cache read failed - \(error.localizedDescription)")
            return nil
        }
    }

    /// Save chart data to Swift Data cache
    private func saveToCache(lineData: [ChartDataPoint], range: ChartTimeRange) {
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

            Logger.chart.debug("CoinDetailViewModel: Saved to cache - \(cacheKey)")
        } catch {
            Logger.chart.warning("CoinDetailViewModel: Cache write failed - \(error.localizedDescription)")
        }
    }
}
