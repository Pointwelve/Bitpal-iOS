//
//  ChartView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import Charts

struct PriceChartView: View {
    let data: [ChartData]
    let currencyPair: CurrencyPair
    
    @State private var selectedPeriod: ChartPeriod = .oneHour
    @State private var chartType: ChartDisplayType = .line
    @State private var isLoading = false
    @State private var interactionState = ChartInteractionState()
    @State private var floaterPosition: FloaterPosition = .topRight
    @State private var memoizedChartData: [ChartData] = []
    @State private var lastDataHash: Int = 0

    @Environment(PriceStreamService.self) private var priceStreamService
    @Environment(HistoricalDataService.self) private var historicalDataService
    
    // MARK: - Chart Data Optimization
    
    private var periodString: String {
        switch selectedPeriod {
        case .oneMinute: return "1M"
        case .fiveMinutes: return "5M"
        case .fifteenMinutes: return "15M" 
        case .thirtyMinutes: return "30M"
        case .oneHour: return "1H"
        case .fourHours: return "4H"
        case .oneDay: return "1D"
        case .oneWeek: return "1W"
        case .oneMonth: return "1M"
        }
    }
    
    private var optimizedChartData: [ChartData] {
        let currentHash = data.count.hashValue ^ chartType.hashValue ^ selectedPeriod.hashValue
        if currentHash != lastDataHash || memoizedChartData.isEmpty {
            memoizedChartData = ChartDataProcessor.optimizeData(data, for: chartType, period: periodString)
            lastDataHash = currentHash
        }
        return memoizedChartData
    }

    // MARK: - Chart Styling
    private var chartLineColor: Color {
        ChartStyling.chartLineColor(for: data, colorScheme: .light)
    }
    
    private var chartAreaGradient: LinearGradient {
        ChartStyling.chartAreaGradient(lineColor: chartLineColor)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart Header
            ChartHeaderView(currencyPair: currencyPair, selectedDataPoint: interactionState.selectedDataPoint)
                .padding(.horizontal)
                .padding(.top)
            
            // Period Selector
            ChartPeriodSelector(selectedPeriod: $selectedPeriod)
                .padding(.horizontal)
            
            // Chart Type Selector
            ChartTypeSelector(selectedType: $chartType)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // Main Chart
            if isLoading {
                ChartLoadingView()
            } else if data.isEmpty {
                ChartEmptyView()
            } else {
                mainChart
            }
            
            // Chart Statistics
            chartStatistics
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            setupChart()
        }
        .onDisappear {
            cleanupChart()
        }
    }
    
    private var mainChart: some View {
        VStack {
            Chart(optimizedChartData) { dataPoint in
                switch chartType {
                case .line:
                    LineMark(
                        x: .value("Time", dataPoint.date),
                        y: .value("Price", dataPoint.close)
                    )
                    .foregroundStyle(chartLineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                case .area:
                    AreaMark(
                        x: .value("Time", dataPoint.date),
                        y: .value("Price", dataPoint.close)
                    )
                    .foregroundStyle(chartAreaGradient)
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Time", dataPoint.date),
                        y: .value("Price", dataPoint.close)
                    )
                    .foregroundStyle(chartLineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                case .candlestick:
                    let isPositive = dataPoint.close >= dataPoint.open
                    let candleColor = isPositive ? Color.green : Color.red
                    let candleWidth = optimizedCandleWidth
                    
                    // Enhanced candlestick wick
                    RuleMark(
                        x: .value("Time", dataPoint.date),
                        yStart: .value("Low", dataPoint.low),
                        yEnd: .value("High", dataPoint.high)
                    )
                    .foregroundStyle(candleColor.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    // Enhanced candlestick body
                    RectangleMark(
                        x: .value("Time", dataPoint.date),
                        yStart: .value("Low", min(dataPoint.open, dataPoint.close)),
                        yEnd: .value("High", max(dataPoint.open, dataPoint.close)),
                        width: .fixed(candleWidth)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: isPositive ? 
                                [Color.green.opacity(0.9), Color.green.opacity(0.7)] : 
                                [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(2)
                    .shadow(color: candleColor.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                
                ChartSelectionOverlay(selectedDataPoint: interactionState.selectedDataPoint, chartType: chartType)
            }
            .frame(height: ChartConfiguration.defaultHeight)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .chartXAxis {
                AxisMarks(values: .stride(by: selectedPeriod.xAxisStride, count: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: selectedPeriod.xAxisFormat)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartBackground { _ in Rectangle().fill(Color.clear) }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    ChartInteractionArea(
                        interactionState: interactionState,
                        geometry: geometry,
                        proxy: proxy,
                        data: optimizedChartData
                    )
                    
                    if let selectedPoint = interactionState.selectedDataPoint {
                        dynamicFloaterView(for: selectedPoint, in: geometry, with: proxy)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var optimizedCandleWidth: CGFloat {
        let dataCount = optimizedChartData.count
        
        switch dataCount {
        case 0...20: return 12
        case 21...50: return 10
        case 51...100: return 8
        case 101...150: return 6
        default: return 4
        }
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
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8), value: position)
        }
    }

    private var chartStatistics: some View {
        VStack(spacing: 12) {
            if !data.isEmpty {
                let stats = ChartStatistics(data: data)
                
                HStack {
                    StatisticCard(title: "24h High", value: CurrencyFormatter.formatCurrencyEnhanced(stats.high24h), color: .green)
                    StatisticCard(title: "24h Low", value: CurrencyFormatter.formatCurrencyEnhanced(stats.low24h), color: .red)
                }
                
                HStack {
                    StatisticCard(title: "Volume", value: CurrencyFormatter.formatVolume(stats.totalVolume), color: .blue)
                    StatisticCard(title: "24h Change", value: "\(stats.changePercent >= 0 ? "+" : "")\(String(format: "%.2f", stats.changePercent))%", color: stats.changePercent >= 0 ? .green : .red)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Lifecycle Management
    
    private func setupChart() {
        Task {
            await priceStreamService.subscribe(to: currencyPair)
        }
        
        if !data.isEmpty {
            floaterPosition = .topRight
        }
    }
    
    private func cleanupChart() {
        Task {
            await priceStreamService.unsubscribe(from: currencyPair)
        }
        
        interactionState.clearSelection()
    }
}

#Preview {
    let samplePair = CurrencyPair(
        baseCurrency: Currency.bitcoin(),
        quoteCurrency: Currency.usd(),
        exchange: Exchange(id: "test", name: "Test", displayName: "Test"),
        sortOrder: 0
    )
    
    PriceChartView(data: [], currencyPair: samplePair)
}