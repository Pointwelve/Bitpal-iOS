//
//  PriceChartView.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import SwiftUI

/// Container view for the price chart with time range selector
/// Coinbase-style: full-bleed chart without card wrapper
struct PriceChartView: View {
    // MARK: - Properties

    let dataPoints: [ChartDataPoint]
    let statistics: ChartStatistics?
    let isLoading: Bool
    let availableRanges: [ChartTimeRange]
    @Binding var selectedRange: ChartTimeRange
    let onRangeChange: (ChartTimeRange) -> Void

    // MARK: - Computed Properties

    private var isPositive: Bool {
        statistics?.isPositive ?? true
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Chart
            ZStack {
                if dataPoints.isEmpty && !isLoading {
                    chartPlaceholder
                } else {
                    LineChartView(
                        dataPoints: dataPoints,
                        isPositive: isPositive
                    )
                    .opacity(isLoading ? 0.5 : 1.0)
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
                onRangeSelected: onRangeChange
            )
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
            dataPoints: generateSampleChartData(),
            statistics: ChartStatistics(
                periodHigh: 46500,
                periodLow: 44000,
                startPrice: 44500,
                endPrice: 45500
            ),
            isLoading: false,
            availableRanges: ChartTimeRange.lineRanges,
            selectedRange: .constant(.oneDay),
            onRangeChange: { _ in }
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
