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
    @State private var showingCreateAlert = false
    @State private var showingMarketAnalysis = false
    @State private var selectedTimePeriod = "1H"
    @State private var chartType: ChartDisplayType = .line
    @State private var interactionState = ChartInteractionState()
    @State private var memoizedChartData: [ChartData] = []
    @State private var lastDataHash: Int = 0
    @State private var preloadedData: [String: [ChartData]] = [:]
    @State private var preloadingPeriods: Set<String> = []
    @State private var priceFlashColor: Color? = nil
    @State private var lastKnownPrice: Double = 0
    
    // MARK: - Constants
    private enum Constants {
        static let chartHeight: CGFloat = 280
        static let priceIconSize: CGFloat = 50
        static let sectionSpacing: CGFloat = 24
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
                navigationHeader
                
                ScrollView {
                    LazyVStack(spacing: Constants.sectionSpacing) {
                        priceSection
                        enhancedChartSection
                        marketStatsGrid
                        Spacer(minLength: Constants.bottomSpacing)
                    }
                    .padding(.horizontal, Constants.horizontalPadding)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateAlert) {
            CreateAlertView()
        }
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
            // Global Average Header
            HStack {
                Text("Global Average")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            chartType = chartType == .line ? .candlestick : .line
                        }
                    } label: {
                        Image(systemName: chartType.systemImage)
                            .font(.caption)
                            .foregroundColor(chartType == .candlestick ? .blue : .secondary)
                            .padding(8)
                            .background(chartType == .candlestick ? Color.blue.opacity(0.2) : Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    
                    Button {
                        // Expand functionality
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
            }
            
            // Enhanced Chart
            modernChart
            
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
        let data = optimizedChartData.isEmpty ? ChartDataProcessor.generateSampleChartData(basePrice: getCurrentPrice()) : optimizedChartData
        let (chartMin, chartMax) = ChartDataProcessor.calculateChartRange(for: data, chartType: chartType)
        
        return Chart(data) { dataPoint in
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
        }
    }
    
    private func chartLine(for dataPoint: ChartData) -> some ChartContent {
        LineMark(
            x: .value("Time", dataPoint.date),
            y: .value("Price", dataPoint.close)
        )
        .foregroundStyle(chartLineColor)
        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        .interpolationMethod(.catmullRom)
    }
    
    @ChartContentBuilder
    private func chartCandlestick(for dataPoint: ChartData) -> some ChartContent {
        let bodyColor = dataPoint.isPositive ? Color.green : Color.red
        
        // High-Low line (wick)
        RectangleMark(
            x: .value("Time", dataPoint.date),
            yStart: .value("Low", dataPoint.low),
            yEnd: .value("High", dataPoint.high),
            width: .fixed(1)
        )
        .foregroundStyle(bodyColor.opacity(0.6))
        
        // Open-Close body
        RectangleMark(
            x: .value("Time", dataPoint.date),
            yStart: .value("Open", min(dataPoint.open, dataPoint.close)),
            yEnd: .value("Close", max(dataPoint.open, dataPoint.close)),
            width: .fixed(8)
        )
        .foregroundStyle(
            LinearGradient(
                colors: [
                    bodyColor.opacity(0.8),
                    bodyColor.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(1)
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
            let offset = position.offset
            let finalPosition = CGPoint(x: chartPosition.x + offset.x, y: chartPosition.y + offset.y)
            
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
        case oneHour = "1H"
        case oneDay = "1D"
        case oneWeek = "1W"
        case oneMonth = "1M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "ALL"
    }
    
    private var marketStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ModernStatCard(
                title: "Market Cap",
                value: "41,375.00 BTC",
                colorScheme: colorScheme
            )
            
            ModernStatCard(
                title: "Volume (24 hours)",
                value: CurrencyFormatter.formatCurrencyEnhanced(98669.59),
                colorScheme: colorScheme
            )
            
            ModernStatCard(
                title: "Available Supply",
                value: "17.332.275",
                colorScheme: colorScheme
            )
            
            ModernStatCard(
                title: "Total Supply",
                value: "17.332.275",
                colorScheme: colorScheme
            )
            
            ModernStatCard(
                title: "Low (24 hours)",
                value: CurrencyFormatter.formatCurrencyEnhanced(98669.59),
                colorScheme: colorScheme
            )
            
            ModernStatCard(
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
        
        do {
            chartData = try await historicalDataService.loadHistoricalData(
                for: currencyPair,
                period: selectedPeriod,
                forceRefresh: forceRefresh
            )
        } catch {
            print("Failed to load chart data: \(error)")
            // Use sample data as fallback
            chartData = ChartDataProcessor.generateSampleChartData(basePrice: getCurrentPrice())
        }
        
        // Update memoized data after loading
        updateMemoizedData(for: chartData, chartType: chartType)
        isLoadingChart = false
    }
    
    private func loadChartDataForPeriod(_ period: String) async {
        guard !isLoadingChart else { return }
        
        isLoadingChart = true
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
            // Store in preloaded cache for future use
            preloadedData[period] = data
        } catch {
            print("Failed to load chart data for period \(period): \(error)")
            chartData = ChartDataProcessor.generateSampleChartData(basePrice: getCurrentPrice())
        }
        
        // Update memoized data after loading
        updateMemoizedData(for: chartData, chartType: chartType)
    }
    
    private func mapStringToChartPeriod(_ period: String) -> ChartPeriod {
        switch period {
        case "1H": .oneHour
        case "1D": .oneDay
        case "1W": .oneWeek
        case "1M": .oneMonth
        case "6M", "1Y", "ALL": .oneMonth // Fallback to oneMonth
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
        let periodsToPreload = ["1D", "1W", "1M"] // Preload common periods
        
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