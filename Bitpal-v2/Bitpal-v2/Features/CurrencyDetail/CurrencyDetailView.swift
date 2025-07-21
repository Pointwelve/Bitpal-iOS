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
    @Bindable var currencyPair: CurrencyPair
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
    @State private var selectedDataPoint: ChartData?
    @State private var selectedTimePeriod = "1D"
    
    // MARK: - Constants
    private enum Constants {
        static let chartHeight: CGFloat = 280
        static let priceIconSize: CGFloat = 50
        static let tooltipPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 20
        static let bottomSpacing: CGFloat = 100
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(.systemGroupedBackground)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var streamKey: String {
        "\(currencyPair.baseCurrency?.symbol ?? "")-\(currencyPair.quoteCurrency?.symbol ?? "")-\(currencyPair.exchange?.id ?? "")"
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
            await loadInitialData()
        }
        .refreshable {
            await refreshData()
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
        VStack(alignment: .leading, spacing: 8) {
            Text(getCurrentPrice().formatted(.currency(code: "USD")))
                .font(.system(size: 36, weight: .bold, design: .default))
                .foregroundColor(primaryTextColor)
            
            priceChangeInfo
        }
    }
    
    private var priceChangeInfo: some View {
        HStack(spacing: 8) {
            let isPositive = currencyPair.priceChangePercent24h >= 0
            let changeColor: Color = isPositive ? .green : .red
            let changePrefix = isPositive ? "+" : ""
            
            Text(changePrefix)
                .foregroundColor(changeColor)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(currencyPair.priceChange24h.formatted(.currency(code: "USD")))
                .foregroundColor(changeColor)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("(\(String(format: "%.2f", currencyPair.priceChangePercent24h))%)")
                .foregroundColor(changeColor)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private var currencyIcon: some View {
        Circle()
            .fill(Color.orange)
            .frame(width: Constants.priceIconSize, height: Constants.priceIconSize)
            .overlay {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
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
                        // Pin functionality
                    } label: {
                        Image(systemName: "pin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray5))
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
        let data = chartData.isEmpty ? generateSampleChartData() : chartData
        let (chartMin, chartMax) = calculateChartRange(for: data)
        
        return Chart(data) { dataPoint in
            chartLine(for: dataPoint)
            chartSelectionIndicator(for: dataPoint)
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
        .overlay(alignment: .topLeading) {
            chartTooltip
        }
        .chartOverlay { proxy in
            chartInteractionOverlay(proxy: proxy)
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
    private func chartSelectionIndicator(for dataPoint: ChartData) -> some ChartContent {
        if let selected = selectedDataPoint, selected.id == dataPoint.id {
            RuleMark(x: .value("Time", selected.date))
                .foregroundStyle(.white.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            
            PointMark(
                x: .value("Time", selected.date),
                y: .value("Price", selected.close)
            )
            .foregroundStyle(.white)
            .symbolSize(80)
            .symbol(.circle)
            
            PointMark(
                x: .value("Time", selected.date),
                y: .value("Price", selected.close)
            )
            .foregroundStyle(.blue)
            .symbolSize(40)
            .symbol(.circle)
        }
    }
    
    private var chartTooltip: some View {
        Group {
            if let selected = selectedDataPoint {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selected.date.formatted(.dateTime.month(.abbreviated).day().hour(.defaultDigits(amPM: .omitted)).minute()))
                        .font(.caption2)
                        .foregroundColor(.white)
                    
                    Text(selected.close.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.top, Constants.tooltipPadding)
                .padding(.leading, Constants.tooltipPadding)
            }
        }
    }
    
    private func chartInteractionOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    handleChartTap(location: location, geometry: geometry, proxy: proxy)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleChartDrag(location: value.location, geometry: geometry, proxy: proxy)
                        }
                )
        }
    }
    
    // MARK: - Chart Helper Properties
    private var chartLineColor: Color {
        colorScheme == .dark ? .white : .blue
    }
    
    private var axisLabelColor: Color {
        (colorScheme == .dark ? Color.white : Color.primary).opacity(0.7)
    }
    
    private func calculateChartRange(for data: [ChartData]) -> (min: Double, max: Double) {
        let minPrice = data.map(\.close).min() ?? 0
        let maxPrice = data.map(\.close).max() ?? 1
        let priceRange = maxPrice - minPrice
        let padding = priceRange * 0.1
        return (max(0, minPrice - padding), maxPrice + padding)
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
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTimePeriod = period
        }
        Task {
            await loadChartDataForPeriod(period)
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
                value: "$98,669.59",
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
                value: "$98,669.59",
                colorScheme: colorScheme
            )
            
            ModernStatCard(
                title: "High (24 hours)",
                value: "11,669.59",
                colorScheme: colorScheme
            )
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func getCurrentPrice() -> Double {
        priceStreamService.prices[streamKey]?.price ?? currencyPair.currentPrice
    }
    
    private func getLatestPriceUpdate() -> Date? {
        priceStreamService.prices[streamKey] != nil ? Date() : currencyPair.lastUpdated
    }
    
    private func loadInitialData() async {
        await loadChartData()
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
            chartData = generateSampleChartData()
        }
        
        isLoadingChart = false
    }
    
    private func loadChartDataForPeriod(_ period: String) async {
        guard !isLoadingChart else { return }
        
        isLoadingChart = true
        defer { isLoadingChart = false }
        
        let chartPeriod = mapStringToChartPeriod(period)
        selectedPeriod = chartPeriod
        
        do {
            chartData = try await historicalDataService.loadHistoricalData(
                for: currencyPair,
                period: chartPeriod,
                forceRefresh: false
            )
        } catch {
            print("Failed to load chart data for period \(period): \(error)")
            chartData = generateSampleChartData()
        }
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
    
    private func generateSampleChartData() -> [ChartData] {
        let basePrice = getCurrentPrice()
        let dataPoints = 24
        
        return (0..<dataPoints).map { i in
            let date = Calendar.current.date(byAdding: .hour, value: -dataPoints + i + 1, to: Date()) ?? Date()
            let progress = Double(i) / Double(dataPoints)
            let trend = basePrice * 0.1 * progress
            let noise = basePrice * Double.random(in: -0.015...0.015)
            let price = max(0.01, basePrice * 0.95 + trend + noise)
            
            return ChartData(
                id: "sample-\(i)",
                date: date,
                open: price,
                high: price * (1 + Double.random(in: 0...0.01)),
                low: price * (1 - Double.random(in: 0...0.01)),
                close: price,
                volume: Double.random(in: 1000...5000)
            )
        }
    }
    
    private func handleChartTap(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        guard let closest = findClosestDataPoint(location: location, geometry: geometry, proxy: proxy) else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDataPoint = closest
        }
    }
    
    private func handleChartDrag(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        selectedDataPoint = findClosestDataPoint(location: location, geometry: geometry, proxy: proxy)
    }
    
    private func findClosestDataPoint(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) -> ChartData? {
        let plotFrame = geometry.frame(in: .local)
        let relativeXPosition = location.x - plotFrame.origin.x
        
        guard let plotValue = proxy.value(atX: relativeXPosition, as: Date.self) else { return nil }
        
        let data = chartData.isEmpty ? generateSampleChartData() : chartData
        return data.min { first, second in
            abs(first.date.timeIntervalSince(plotValue)) < abs(second.date.timeIntervalSince(plotValue))
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume > 1_000_000_000 {
            return String(format: "%.2fB", volume / 1_000_000_000)
        } else if volume > 1_000_000 {
            return String(format: "%.2fM", volume / 1_000_000)
        } else if volume > 1_000 {
            return String(format: "%.2fK", volume / 1_000)
        } else {
            return String(format: "%.2f", volume)
        }
    }
}

// MARK: - Supporting Views

struct TimePeriodButton: View {
    let period: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(period)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(minWidth: 32, minHeight: 28)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.blue : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            colorScheme == .dark 
                ? Color(.systemGray6).opacity(0.3)
                : Color(.systemBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

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