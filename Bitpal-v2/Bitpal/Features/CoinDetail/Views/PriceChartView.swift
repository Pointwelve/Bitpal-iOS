//
//  PriceChartView.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import SwiftUI

/// Container view for the price chart with chart type toggle and time range selector
/// Coinbase-style: full-bleed chart without card wrapper
struct PriceChartView: View {
    // MARK: - Properties

    let lineDataPoints: [ChartDataPoint]
    let candleDataPoints: [CandleDataPoint]
    let statistics: ChartStatistics?
    let isLoading: Bool
    let availableRanges: [ChartTimeRange]
    @Binding var selectedRange: ChartTimeRange
    @Binding var selectedChartType: ChartType
    let onRangeChange: (ChartTimeRange) -> Void
    let onChartTypeChange: (ChartType) -> Void

    // MARK: - Computed Properties

    private var isPositive: Bool {
        statistics?.isPositive ?? true
    }

    private var hasData: Bool {
        switch selectedChartType {
        case .line:
            return !lineDataPoints.isEmpty
        case .candle:
            return !candleDataPoints.isEmpty
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.small) {
            // Chart type toggle
            HStack {
                Spacer()
                ChartTypeToggle(
                    selectedType: $selectedChartType,
                    onTypeChanged: onChartTypeChange
                )
            }

            // Chart
            ZStack {
                if !hasData && !isLoading {
                    chartPlaceholder
                } else {
                    chartView
                        .opacity(isLoading ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedChartType)
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                }
            }

            // Time range selector
            TimeRangeSelector(
                ranges: availableRanges,
                selectedRange: $selectedRange,
                chartType: selectedChartType,
                onRangeSelected: onRangeChange
            )
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        switch selectedChartType {
        case .line:
            LineChartView(
                dataPoints: lineDataPoints,
                isPositive: isPositive
            )
        case .candle:
            CandlestickChartView(candles: candleDataPoints)
        }
    }

    // MARK: - Subviews

    private var chartPlaceholder: some View {
        Rectangle()
            .fill(Color.backgroundSecondary.opacity(0.1))
            .frame(height: 200)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.medium) {
        PriceChartView(
            lineDataPoints: generateSampleChartData(),
            candleDataPoints: generateSampleCandleData(),
            statistics: ChartStatistics(
                periodHigh: 46500,
                periodLow: 44000,
                startPrice: 44500,
                endPrice: 45500
            ),
            isLoading: false,
            availableRanges: ChartTimeRange.lineRanges,
            selectedRange: .constant(.oneDay),
            selectedChartType: .constant(.line),
            onRangeChange: { _ in },
            onChartTypeChange: { _ in }
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}

// MARK: - Preview Helpers

private func generateSampleChartData() -> [ChartDataPoint] {
    let basePrice: Double = 45000
    let now = Date()

    return (0..<24).map { hour in
        let timestamp = now.addingTimeInterval(Double(-24 + hour) * 3600)
        let variance = Double.random(in: -500...500)
        let trendOffset = Double(hour) * 50
        let price = Decimal(basePrice + trendOffset + variance)
        return ChartDataPoint(timestamp: timestamp, price: price)
    }
}

private func generateSampleCandleData() -> [CandleDataPoint] {
    let basePrice: Double = 45000
    let now = Date()

    return (0..<20).map { i in
        let timestamp = now.addingTimeInterval(Double(-20 + i) * 3600 * 4)
        let variance = Double.random(in: -1000...1000)
        let open = Decimal(basePrice + variance)
        let closeVariance = Double.random(in: -500...500)
        let close = Decimal(basePrice + variance + closeVariance)
        let high = max(open, close) + Decimal(Double.random(in: 100...300))
        let low = min(open, close) - Decimal(Double.random(in: 100...300))

        return CandleDataPoint(
            timestamp: timestamp,
            open: open,
            high: high,
            low: low,
            close: close
        )
    }
}
