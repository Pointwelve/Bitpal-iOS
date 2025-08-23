//
//  CurrencyDetailView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData
import Charts

struct CurrencyDetailView: View {
    let currencyPair: CurrencyPair
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(HistoricalDataService.self) private var historicalDataService
    @Environment(PriceStreamService.self) private var priceStreamService
    @Environment(TechnicalAnalysisService.self) private var technicalAnalysisService
    
    @State private var chartData: [ChartData] = []
    @State private var selectedPeriod: ChartPeriod = .oneDay
    @State private var isLoadingChart = false
    @State private var showingMarketAnalysis = false
    @State private var selectedTimePeriod = "1D"
    @State private var chartType: ChartDisplayType = .line
    @State private var interactionState = ChartInteractionState()
    @State private var memoizedChartData: [ChartData] = []
    @State private var lastDataHash: Int = 0
    @State private var preloadedData: [String: [ChartData]] = [:]
    @State private var preloadingPeriods: Set<String> = []
    @State private var priceFlashColor: Color? = nil
    @State private var lastKnownPrice: Double = 0
    @State private var chartLoadError: String? = nil
    
    // MARK: - Constants
    private enum Constants {
        static let chartHeight: CGFloat = 280
        static let priceIconSize: CGFloat = 50
        static let sectionSpacing: CGFloat = 32 // Increased for better visual separation
        static let horizontalPadding: CGFloat = 20
        static let bottomSpacing: CGFloat = 100
    }
    
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        ChartStyling.backgroundColor(colorScheme: colorScheme)
    }
    
    private var primaryTextColor: Color {
        ChartStyling.primaryTextColor(colorScheme: colorScheme)
    }
    
    private var optimizedChartData: [ChartData] {
        // Check if we have preloaded data for the current period
        if let preloaded = preloadedData[selectedTimePeriod], !preloaded.isEmpty {
            return ChartDataProcessor.optimizeData(preloaded, for: chartType, period: selectedTimePeriod)
        }
        return memoizedChartData.isEmpty ? ChartDataProcessor.optimizeData(chartData, for: chartType, period: selectedTimePeriod) : memoizedChartData
    }
    
    private var streamKey: String {
        // Match the StreamPrice uniqueKey format
        let base = currencyPair.baseCurrency?.symbol ?? ""
        let quote = currencyPair.quoteCurrency?.symbol ?? ""
        return "cadli-\(base)-\(quote)"
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                modernHeader
                
                ScrollView {
                    LazyVStack(spacing: Constants.sectionSpacing) {
                        modernPriceSection
                        enhancedChartSection
                        horizontalStatsSection
                        Spacer(minLength: Constants.bottomSpacing)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            lastKnownPrice = getCurrentPrice()
            print("🚀 CurrencyDetailView task started for: \(streamKey)")
            print("🔗 Starting streaming for currency pair: \(currencyPair.displayName)")
            
            // Start streaming for this specific currency pair
            await priceStreamService.subscribe(to: currencyPair)
            
            await loadInitialData()
        }
        .refreshable {
            await refreshData()
        }
        .onChange(of: chartData) { _, newData in
            updateMemoizedData(for: newData, chartType: chartType)
        }
        .onChange(of: chartType) { _, newType in
            updateMemoizedData(for: chartData, chartType: newType)
        }
    }
    
    // MARK: - Modern UI Components
    
    private var modernHeader: some View {
        ModernDetailHeader(
            currencyPair: currencyPair,
            onBack: { dismiss() },
            onMenu: { /* Menu actions */ }
        )
        .padding(.top, 10)
    }
    
    private var modernPriceSection: some View {
        ModernPriceDisplay(
            currentPrice: getCurrentPrice(),
            priceChange: getCurrentPriceChange(),
            priceChangePercent: getCurrentPriceChangePercent(),
            flashColor: priceFlashColor,
            onPriceChange: handlePriceChange
        )
        .padding(.horizontal, Constants.horizontalPadding)
    }
    
    
    private var horizontalStatsSection: some View {
        HorizontalStatCards(currencyPair: currencyPair)
    }
    
    
    // MARK: - Legacy Components (keeping for chart functionality)
    
    private var navigationHeader: some View {
        HStack {
            backButton
            Spacer()
            currencyTitle
            Spacer()
            menuButton
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, 10)
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(primaryTextColor)
        }
    }
    
    private var currencyTitle: some View {
        VStack(spacing: 2) {
            Text(currencyPair.baseCurrency?.name ?? "Unknown")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(primaryTextColor)
            
            Text("(\(currencyPair.baseCurrency?.symbol ?? "N/A"))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var menuButton: some View {
        Button(action: { /* Menu actions */ }) {
            Image(systemName: "ellipsis")
                .font(.title2)
                .foregroundColor(primaryTextColor)
        }
    }
    
    private var priceSection: some View {
        HStack {
            priceInfo
            Spacer()
            currencyIcon
        }
    }
    
    private var priceInfo: some View {
        ChartPriceChangeView(
            currentPrice: getCurrentPrice(),
            priceChange: getCurrentPriceChange(),
            priceChangePercent: getCurrentPriceChangePercent(),
            flashColor: priceFlashColor,
            onPriceChange: handlePriceChange
        )
    }
    
    private var currencyIcon: some View {
        CurrencyIcon(
            currency: currencyPair.baseCurrency,
            size: Constants.priceIconSize
        )
    }
    
    private var enhancedChartSection: some View {
        VStack(spacing: 16) {
            // Modern Chart Header
            EnhancedChartHeader(
                chartType: $chartType,
                onExpand: { /* Expand functionality */ }
            )
            .padding(.horizontal, Constants.horizontalPadding)
            
            // Enhanced Chart
            modernChart
                .padding(.horizontal, Constants.horizontalPadding)
            
            // Time Period Selector
            timePeriodSelector
        }
    }
    
    private var modernChart: some View {
        ZStack {
            if isLoadingChart {
                chartLoadingView
                    .transition(.opacity)
            } else {
                chartContentView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isLoadingChart)
    }
    
    private var chartContentView: some View {
        // Show error view if there's an error or no data
        if let errorMessage = chartLoadError {
            return AnyView(
                ChartErrorView(
                    errorMessage: errorMessage,
                    onRetry: {
                        Task {
                            await loadChartDataForPeriod(selectedTimePeriod)
                        }
                    }
                )
            )
        }
        
        let data = optimizedChartData
        guard !data.isEmpty else {
            return AnyView(
                ChartErrorView(
                    errorMessage: "No chart data available",
                    onRetry: {
                        Task {
                            await loadChartDataForPeriod(selectedTimePeriod)
                        }
                    }
                )
            )
        }
        
        let (chartMin, chartMax) = ChartDataProcessor.calculateChartRange(for: data, chartType: chartType)
        
        return AnyView(Chart(data) { dataPoint in
            switch chartType {
            case .line:
                chartLine(for: dataPoint)
            case .candlestick:
                chartCandlestick(for: dataPoint)
            case .area:
                AreaMark(
                    x: .value("Time", dataPoint.date),
                    y: .value("Price", dataPoint.close)
                )
                .foregroundStyle(ChartStyling.chartAreaGradient(lineColor: chartLineColor))
                .interpolationMethod(.catmullRom)
            }
            
            ChartSelectionOverlay(selectedDataPoint: interactionState.selectedDataPoint, chartType: chartType)
        }
        .frame(height: Constants.chartHeight)
        .chartYScale(domain: chartMin...chartMax)
        .chartBackground { _ in Rectangle().fill(Color.clear) }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { _ in
                AxisValueLabel()
                    .foregroundStyle(axisLabelColor)
                    .font(.caption)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                ChartInteractionArea(
                    interactionState: interactionState,
                    geometry: geometry,
                    proxy: proxy,
                    data: data
                )
                
                if let selectedPoint = interactionState.selectedDataPoint {
                    dynamicFloaterView(for: selectedPoint, in: geometry, with: proxy)
                }
            }
        })
    }
    
    private func chartLine(for dataPoint: ChartData) -> some ChartContent {
        LineMark(
            x: .value("Time", dataPoint.date),
            y: .value("Price", dataPoint.close)
        )
        .foregroundStyle(chartLineColor)
        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    private func chartCandlestick(for dataPoint: ChartData) -> some ChartContent {
        let bodyColor = dataPoint.isPositive ? Color.green : Color.red
        let candlestickWidth = calculateCandlestickWidth()
        // Improved wick visibility with minimum width of 2
        let wickWidth = max(2, candlestickWidth / 6)
        
        // High-Low line (wick) - more visible
        RectangleMark(
            x: .value("Time", dataPoint.date),
            yStart: .value("Low", dataPoint.low),
            yEnd: .value("High", dataPoint.high),
            width: .fixed(wickWidth)
        )
        .foregroundStyle(bodyColor.opacity(0.7))
        
        // Open-Close body - natural data values
        RectangleMark(
            x: .value("Time", dataPoint.date),
            yStart: .value("Open", min(dataPoint.open, dataPoint.close)),
            yEnd: .value("Close", max(dataPoint.open, dataPoint.close)),
            width: .fixed(candlestickWidth)
        )
        .foregroundStyle(
            LinearGradient(
                colors: [
                    bodyColor.opacity(0.9),
                    bodyColor.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(1.5)
    }
    
    // MARK: - Dynamic Candlestick Width
    
    private func calculateCandlestickWidth() -> CGFloat {
        return 7  // Standardized width for all periods
    }
    
    
    
    
    // MARK: - Chart Helper Properties
    private var chartLineColor: Color {
        ChartStyling.chartLineColor(for: chartData, colorScheme: colorScheme)
    }
    
    private var axisLabelColor: Color {
        ChartStyling.axisLabelColor(colorScheme: colorScheme)
    }
    
    @ViewBuilder
    private func dynamicFloaterView(for dataPoint: ChartData, in geometry: GeometryProxy, with proxy: ChartProxy) -> some View {
        if let xPosition = proxy.position(forX: dataPoint.date),
           let yPosition = proxy.position(forY: dataPoint.close) {
            
            let chartPosition = CGPoint(x: xPosition, y: yPosition)
            let isLeftHalf = chartPosition.x < geometry.frame(in: .local).midX
            let position: FloaterPosition = isLeftHalf ? .topRight : .topLeft
            
            // Position card above the chart to avoid overlap
            let finalPosition = CGPoint(
                x: max(50, min(chartPosition.x, geometry.size.width - 50)), // Keep within bounds
                y: max(20, chartPosition.y - 60) // Always position above, with safe margin
            )
            
            ChartFloaterView(
                dataPoint: dataPoint,
                currencyPair: currencyPair,
                position: position
            )
            .position(finalPosition)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.easeOut(duration: 0.2), value: position)
        }
    }
    
    private var timePeriodSelector: some View {
        HStack(spacing: 4) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                TimePeriodButton(
                    period: period.rawValue,
                    isSelected: selectedTimePeriod == period.rawValue
                ) {
                    selectTimePeriod(period.rawValue)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func selectTimePeriod(_ period: String) {
        // Immediate visual feedback for button selection
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTimePeriod = period
        }
        
        // Clear interaction state smoothly
        withAnimation(.easeOut(duration: 0.3)) {
            interactionState.clearSelection()
        }
        
        // Check if we have preloaded data for this period
        if let preloaded = preloadedData[period], !preloaded.isEmpty {
            // Use preloaded data immediately
            chartData = preloaded
            updateMemoizedData(for: preloaded, chartType: chartType)
        } else {
            // Load new data with loading state
            Task {
                // Add small delay for smoother transition
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await loadChartDataForPeriod(period)
            }
        }
    }
    
    // MARK: - Helper Types
    private enum TimePeriod: String, CaseIterable {
        case fifteenMinutes = "15m"
        case oneHour = "1h"
        case fourHours = "4h"
        case oneDay = "1D"
        case oneWeek = "1W"
        case oneYear = "1Y"
    }
    
    // Legacy market stats grid - keeping for reference but not used in new design
    private var marketStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            LegacyStatCard(
                title: "Market Cap",
                value: "41,375.00 BTC",
                colorScheme: colorScheme
            )
            
            LegacyStatCard(
                title: "Volume (24 hours)",
                value: CurrencyFormatter.formatCurrencyEnhanced(98669.59),
                colorScheme: colorScheme
            )
            
            LegacyStatCard(
                title: "Available Supply",
                value: "17.332.275",
                colorScheme: colorScheme
            )
            
            LegacyStatCard(
                title: "Total Supply",
                value: "17.332.275",
                colorScheme: colorScheme
            )
            
            LegacyStatCard(
                title: "Low (24 hours)",
                value: CurrencyFormatter.formatCurrencyEnhanced(98669.59),
                colorScheme: colorScheme
            )
            
            LegacyStatCard(
                title: "High (24 hours)",
                value: CurrencyFormatter.formatCurrencyEnhanced(11669.59),
                colorScheme: colorScheme
            )
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func getCurrentPrice() -> Double {
        priceStreamService.prices[streamKey]?.price ?? currencyPair.currentPrice
    }
    
    private func getCurrentPriceChange() -> Double {
        // Use API/model data as primary source
        let modelChange = currencyPair.priceChange24h
        print("💾 API/Model 24h price change: \(modelChange)")
        
        // If model data is available and non-zero, use it
        if modelChange != 0 {
            return modelChange
        }
        
        // Only check stream data if model data is unavailable or zero
        if let streamPrice = priceStreamService.prices[streamKey] {
            print("🔄 Stream data found for key: \(streamKey)")
            print("📊 Stream price: \(streamPrice.price ?? 0), open24h: \(streamPrice.open24Hour ?? 0), change: \(streamPrice.priceChange24h)")
            return streamPrice.priceChange24h
        } else {
            print("❌ No stream data for key: \(streamKey)")
            print("🔍 Available keys: \(Array(priceStreamService.prices.keys))")
            return modelChange // Return model data (could be 0)
        }
    }
    
    private func getCurrentPriceChangePercent() -> Double {
        // Use API/model data as primary source
        let modelPercent = currencyPair.priceChangePercent24h
        print("📉 API/Model 24h change percent: \(modelPercent)")
        print("💾 Model data - current: \(currencyPair.currentPrice), change24h: \(currencyPair.priceChange24h)")
        
        // If model data is available and non-zero, use it
        if modelPercent != 0 {
            return modelPercent
        }
        
        // Only check stream data if model data is unavailable or zero
        if let streamPrice = priceStreamService.prices[streamKey] {
            let streamPercent = streamPrice.priceChangePercent24h
            print("📈 Stream 24h change percent: \(streamPercent)")
            print("📊 Stream data - current: \(streamPrice.price ?? 0), open24h: \(streamPrice.open24Hour ?? 0)")
            
            if streamPercent != 0 {
                return streamPercent
            }
        } else {
            print("❌ No stream data for key: \(streamKey)")
            print("🔍 Available stream keys: \(Array(priceStreamService.prices.keys))")
        }
        
        // If both model and stream data are zero, try to calculate manually from available API data
        let currentPrice = getCurrentPrice()
        if currentPrice > 0 && currencyPair.priceChange24h != 0 {
            // Calculate percentage from absolute change and current price
            let calculatedPercent = (currencyPair.priceChange24h / (currentPrice - currencyPair.priceChange24h)) * 100
            print("🧮 Calculated 24h percent from API data: \(calculatedPercent)%")
            return calculatedPercent
        }
        
        print("⚠️ No valid 24h price change data available from API or stream")
        return 0 // Return 0 instead of sample data
    }
    
    private func getLatestPriceUpdate() -> Date? {
        priceStreamService.prices[streamKey] != nil ? Date() : currencyPair.lastUpdated
    }
    
    private func handlePriceChange(_ newPrice: Double) {
        if lastKnownPrice > 0 {
            let flashColor = newPrice > lastKnownPrice ? Color.green : Color.red
            priceFlashColor = flashColor
            
            // Clear the flash color after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                priceFlashColor = nil
            }
        }
        lastKnownPrice = newPrice
    }
    
    private func loadInitialData() async {
        await loadChartData()
        // Start preloading other periods in background
        await preloadOtherPeriods()
    }
    
    private func refreshData() async {
        await loadChartData(forceRefresh: true)
    }
    
    private func loadChartData(forceRefresh: Bool = false) async {
        isLoadingChart = true
        chartLoadError = nil
        
        do {
            chartData = try await historicalDataService.loadHistoricalData(
                for: currencyPair,
                period: selectedPeriod,
                forceRefresh: forceRefresh
            )
            chartLoadError = nil
        } catch {
            print("Failed to load chart data: \(error)")
            chartLoadError = "Chart data not available for this time period"
            chartData = []
        }
        
        // Update memoized data after loading
        updateMemoizedData(for: chartData, chartType: chartType)
        isLoadingChart = false
    }
    
    private func loadChartDataForPeriod(_ period: String) async {
        guard !isLoadingChart else { return }
        
        isLoadingChart = true
        chartLoadError = nil
        defer { isLoadingChart = false }
        
        let chartPeriod = mapStringToChartPeriod(period)
        selectedPeriod = chartPeriod
        
        do {
            let data = try await historicalDataService.loadHistoricalData(
                for: currencyPair,
                period: chartPeriod,
                forceRefresh: false
            )
            
            chartData = data
            chartLoadError = nil
            // Store in preloaded cache for future use
            preloadedData[period] = data
        } catch {
            print("Failed to load chart data for period \(period): \(error)")
            chartLoadError = "Chart data not available for \(period) time period"
            chartData = []
        }
        
        // Update memoized data after loading
        updateMemoizedData(for: chartData, chartType: chartType)
    }
    
    private func mapStringToChartPeriod(_ period: String) -> ChartPeriod {
        switch period {
        case "15m": .fifteenMinutes
        case "1h": .oneHour
        case "4h": .fourHours
        case "1D": .oneDay
        case "1W": .oneWeek
        case "1Y": .oneMonth // Map to oneMonth until yearly data is available
        default: .oneDay
        }
    }
    
    private func updateMemoizedData(for data: [ChartData], chartType: ChartDisplayType) {
        let currentHash = data.count.hashValue ^ chartType.hashValue ^ selectedTimePeriod.hashValue
        if currentHash != lastDataHash || memoizedChartData.isEmpty {
            memoizedChartData = ChartDataProcessor.optimizeData(data, for: chartType, period: selectedTimePeriod)
            lastDataHash = currentHash
        }
    }
    
    private func preloadOtherPeriods() async {
        let periodsToPreload = ["1h", "4h", "1W"] // Preload common periods
        
        await withTaskGroup(of: Void.self) { group in
            for period in periodsToPreload {
                if period != selectedTimePeriod && !preloadingPeriods.contains(period) {
                    group.addTask {
                        await self.preloadPeriodData(period)
                    }
                }
            }
        }
    }
    
    private func preloadPeriodData(_ period: String) async {
        guard !preloadingPeriods.contains(period) else { return }
        
        preloadingPeriods.insert(period)
        defer { preloadingPeriods.remove(period) }
        
        let chartPeriod = mapStringToChartPeriod(period)
        
        do {
            let data = try await historicalDataService.loadHistoricalData(
                for: currencyPair,
                period: chartPeriod,
                forceRefresh: false
            )
            
            await MainActor.run {
                preloadedData[period] = data
            }
        } catch {
            print("Failed to preload data for period \(period): \(error)")
        }
    }
    
    private var chartLoadingView: some View {
        VStack(spacing: 20) {
            // Skeleton chart lines
            chartSkeletonView
            
            Spacer()
            
            // Animated loading dots with message
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .scaleEffect(animateDots ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: animateDots
                            )
                    }
                }
                
                Text("Loading \(selectedTimePeriod) data...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }
        }
        .frame(height: Constants.chartHeight)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.tertiary, lineWidth: 1)
                )
        )
        .onAppear {
            animateDots = true
        }
    }
    
    private var chartSkeletonView: some View {
        VStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { lineIndex in
                HStack {
                    ForEach(0..<8, id: \.self) { pointIndex in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 25, height: CGFloat.random(in: 8...30))
                            .opacity(animateSkeleton ? 0.3 : 0.7)
                            .animation(
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(lineIndex + pointIndex) * 0.1),
                                value: animateSkeleton
                            )
                        
                        if pointIndex < 7 {
                            Spacer(minLength: 4)
                        }
                    }
                }
            }
        }
        .padding(.top, 20)
        .onAppear {
            animateSkeleton = true
        }
    }
    
    @State private var animateSkeleton = false
    
    @State private var animateDots = false
    
}

// MARK: - Chart Error View

struct ChartErrorView: View {
    let errorMessage: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .opacity(0.6)
            
            VStack(spacing: 8) {
                Text("Data Unavailable")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Retry")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.tertiary, lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Views


struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let samplePair = CurrencyPair(
        baseCurrency: Currency.bitcoin(),
        quoteCurrency: Currency.usd(),
        exchange: Exchange(id: "test", name: "Test", displayName: "Test"),
        sortOrder: 0
    )
    
    CurrencyDetailView(currencyPair: samplePair)
        .environment(HistoricalDataService.shared)
        .environment(PriceStreamService.shared)
}