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
    
    @State private var selectedPeriod: ChartPeriod = .oneDay
    @State private var chartType: ChartDisplayType = .line
    @State private var selectedDataPoint: ChartData?
    @State private var isLoading = false
    
    // Performance optimization constants
    private static let maxDataPoints = 200
    private static let maxCandlestickPoints = 100
    
    enum ChartDisplayType: String, CaseIterable {
        case line = "Line"
        case candlestick = "Candlestick"
        case area = "Area"
        
        var systemImage: String {
            switch self {
            case .line: return "chart.line.uptrend.xyaxis"
            case .candlestick: return "chart.bar.fill"
            case .area: return "chart.line.flattrend.xyaxis.fill"
            }
        }
    }
    
    // MARK: - Chart Styling
    private var chartLineColor: Color {
        if let first = data.first, let last = data.last {
            return last.close >= first.close ? .green : .red
        }
        return .accentColor
    }
    
    private var chartAreaGradient: LinearGradient {
        LinearGradient(
            colors: [
                chartLineColor.opacity(0.4),
                chartLineColor.opacity(0.1),
                chartLineColor.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart Header
            chartHeader
            
            // Period Selector
            ChartPeriodSelector(selectedPeriod: $selectedPeriod)
                .padding(.horizontal)
            
            // Chart Type Selector
            chartTypeSelector
            
            // Main Chart
            if isLoading {
                chartLoadingView
            } else if data.isEmpty {
                chartEmptyView
            } else {
                mainChart
            }
            
            // Chart Statistics
            chartStatistics
        }
        .background(Color(.systemGroupedBackground))
        // Data loading is handled by parent view (CurrencyDetailView)
    }
    
    private var chartHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text(currencyPair.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(selectedDataPoint?.close.formatted(.currency(code: "USD")) ?? currencyPair.currentPrice.formatted(.currency(code: "USD")))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let point = selectedDataPoint {
                        Text(point.date.formatted(.dateTime.month().day().hour().minute()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: currencyPair.isPositiveChange ? "arrow.up" : "arrow.down")
                                .foregroundColor(currencyPair.isPositiveChange ? .green : .red)
                                .font(.caption)
                            
                            Text("\(currencyPair.isPositiveChange ? "+" : "")\(String(format: "%.2f", currencyPair.priceChangePercent24h))%")
                                .foregroundColor(currencyPair.isPositiveChange ? .green : .red)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    private var chartTypeSelector: some View {
        HStack {
            ForEach(ChartDisplayType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        chartType = type
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: type.systemImage)
                            .font(.caption)
                        Text(type.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        chartType == type ? Color.accentColor : Color(.systemGray5)
                    )
                    .foregroundColor(
                        chartType == type ? .white : .primary
                    )
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var mainChart: some View {
        VStack {
            Chart(optimizedData) { dataPoint in
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
                    
                    // Candlestick body
                    RectangleMark(
                        x: .value("Time", dataPoint.date),
                        yStart: .value("Low", min(dataPoint.open, dataPoint.close)),
                        yEnd: .value("High", max(dataPoint.open, dataPoint.close)),
                        width: .fixed(candleWidth)
                    )
                    .foregroundStyle(candleColor)
                    .cornerRadius(1)
                    
                    // Candlestick wick
                    RuleMark(
                        x: .value("Time", dataPoint.date),
                        yStart: .value("Low", dataPoint.low),
                        yEnd: .value("High", dataPoint.high)
                    )
                    .foregroundStyle(candleColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
                
                // Selection indicator
                if let selected = selectedDataPoint, selected.id == dataPoint.id {
                    RuleMark(x: .value("Time", selected.date))
                        .foregroundStyle(.primary.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value("Price", selected.close)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(120)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value("Price", selected.close)
                    )
                    .foregroundStyle(chartLineColor)
                    .symbolSize(80)
                }
            }
            .frame(height: 320)
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
                                .onEnded { _ in
                                    // Optionally clear selection after drag ends
                                    // selectedDataPoint = nil
                                }
                        )
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Performance Optimizations
    
    private var optimizedData: [ChartData] {
        guard data.count > Self.maxDataPoints else { return data }
        
        return decimateData(data, targetCount: Self.maxDataPoints)
    }
    
    private var optimizedCandleWidth: CGFloat {
        let dataCount = optimizedData.count
        
        switch dataCount {
        case 0...20: return 12
        case 21...50: return 10
        case 51...100: return 8
        case 101...150: return 6
        default: return 4
        }
    }
    
    private func decimateData(_ data: [ChartData], targetCount: Int) -> [ChartData] {
        guard data.count > targetCount else { return data }
        
        let step = Double(data.count) / Double(targetCount)
        var result: [ChartData] = []
        
        for i in 0..<targetCount {
            let index = min(Int(Double(i) * step), data.count - 1)
            result.append(data[index])
        }
        
        return result
    }
    
    private var chartLoadingView: some View {
        VStack {
            ProgressView()
            Text("Loading chart data...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(height: 300)
    }
    
    private var chartEmptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No chart data available")
                .font(.headline)
            
            Text("Chart data for this period is not available")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
    }
    
    private var chartStatistics: some View {
        VStack(spacing: 12) {
            if !data.isEmpty {
                let stats = ChartStatistics(data: data)
                
                HStack {
                    StatisticCard(title: "24h High", value: stats.high24h.formatted(.currency(code: "USD")), color: .green)
                    StatisticCard(title: "24h Low", value: stats.low24h.formatted(.currency(code: "USD")), color: .red)
                }
                
                HStack {
                    StatisticCard(title: "Volume", value: formatVolume(stats.totalVolume), color: .blue)
                    StatisticCard(title: "Change", value: "\(stats.changePercent >= 0 ? "+" : "")\(String(format: "%.2f", stats.changePercent))%", color: stats.changePercent >= 0 ? .green : .red)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func handleChartTap(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        let plotFrame = geometry.frame(in: .local)
        let relativeXPosition = location.x - plotFrame.origin.x
        
        guard let plotValue = proxy.value(atX: relativeXPosition, as: Date.self), !data.isEmpty else {
            return
        }
        
        // Optimized binary search for closest data point
        let closest = findClosestDataPoint(to: plotValue)
        
        if closest?.id != selectedDataPoint?.id {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDataPoint = closest
            }
        }
    }
    
    private func handleChartDrag(location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        handleChartTap(location: location, geometry: geometry, proxy: proxy)
    }
    
    private func findClosestDataPoint(to targetDate: Date) -> ChartData? {
        let searchData = optimizedData
        guard !searchData.isEmpty else { return nil }
        
        // Binary search for better performance with large datasets
        if searchData.count > 50 {
            return binarySearchClosest(in: searchData, target: targetDate)
        } else {
            // Linear search for small datasets
            return searchData.min { first, second in
                abs(first.date.timeIntervalSince(targetDate)) < abs(second.date.timeIntervalSince(targetDate))
            }
        }
    }
    
    private func binarySearchClosest(in sortedData: [ChartData], target: Date) -> ChartData? {
        guard !sortedData.isEmpty else { return nil }
        
        var left = 0
        var right = sortedData.count - 1
        var closest = sortedData[0]
        var minDiff = abs(sortedData[0].date.timeIntervalSince(target))
        
        while left <= right {
            let mid = (left + right) / 2
            let current = sortedData[mid]
            let diff = abs(current.date.timeIntervalSince(target))
            
            if diff < minDiff {
                minDiff = diff
                closest = current
            }
            
            if current.date < target {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        return closest
    }
    
    
    private func generateSampleData() async {
        // Generate realistic sample data based on current price
        let basePrice = currencyPair.currentPrice
        var generatedData: [ChartData] = []
        let dataPoints = selectedPeriod.dataPointCount
        let interval = selectedPeriod.intervalMinutes
        
        for i in 0..<dataPoints {
            let date = Calendar.current.date(byAdding: .minute, value: -(dataPoints - i) * interval, to: Date()) ?? Date()
            
            // Generate realistic price variation
            let variation = Double.random(in: -0.05...0.05) // 5% variation
            let price = basePrice * (1 + variation)
            
            let open = i == 0 ? price : generatedData[i-1].close
            let close = price
            let high = max(open, close) * (1 + Double.random(in: 0...0.02))
            let low = min(open, close) * (1 - Double.random(in: 0...0.02))
            let volume = Double.random(in: 1000...10000)
            
            generatedData.append(ChartData(
                id: UUID().uuidString,
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await MainActor.run {
            // Use the generated data - in real implementation this would come from API
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
            return String(format: "%.0f", volume)
        }
    }
}

// MARK: - Supporting Views

struct ChartPeriodSelector: View {
    @Binding var selectedPeriod: ChartPeriod
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChartPeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedPeriod == period ? Color.accentColor : Color(.systemGray5)
                            )
                            .foregroundColor(
                                selectedPeriod == period ? .white : .primary
                            )
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

// MARK: - Data Models

// ChartData is now defined in Core/Models/HistoricalPrice.swift

// ChartPeriod is now defined in Core/Models/HistoricalPrice.swift

struct ChartStatistics {
    let high24h: Double
    let low24h: Double
    let totalVolume: Double
    let changePercent: Double
    
    init(data: [ChartData]) {
        high24h = data.map(\.high).max() ?? 0
        low24h = data.map(\.low).min() ?? 0
        totalVolume = data.map(\.volume).reduce(0, +)
        
        if let first = data.first, let last = data.last {
            changePercent = ((last.close - first.open) / first.open) * 100
        } else {
            changePercent = 0
        }
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