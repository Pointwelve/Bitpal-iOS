//
//  CandlestickChartView.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/7/25.
//

import SwiftUI
import Charts
import UIKit

/// Candlestick chart view for displaying OHLC price data
/// Per Constitution Principle I: Performance optimized with limited data points
/// Per Constitution Principle II: Liquid Glass design
struct CandlestickChartView: View {
    // MARK: - Properties

    let candles: [CandleDataPoint]

    // MARK: - Touch Interaction State

    @State private var selectedCandle: CandleDataPoint?
    @State private var selectedCandlePosition: CGPoint = .zero
    @State private var plotFrameSize: CGSize = .zero
    @State private var chartWidth: CGFloat = 0

    // MARK: - Haptic Feedback

    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Computed Properties

    /// Candles with index for evenly-spaced X positioning
    private var indexedCandles: [(index: Int, candle: CandleDataPoint)] {
        candles.enumerated().map { ($0.offset, $0.element) }
    }

    /// Dynamic candle body width based on chart width and candle count
    private var candleBodyWidth: MarkDimension {
        guard candles.count > 0, chartWidth > 0 else { return .fixed(8) }
        // Calculate width: 80% of available space per candle for body
        let spacePerCandle = chartWidth / CGFloat(candles.count)
        let calculatedWidth = spacePerCandle * 0.75
        // Clamp between 3 and 24 pixels
        let clampedWidth = min(max(calculatedWidth, 3), 24)
        return .fixed(clampedWidth)
    }

    /// Dynamic wick width (thinner than body, minimum 1)
    private var wickWidth: MarkDimension {
        guard candles.count > 0, chartWidth > 0 else { return .fixed(1) }
        let spacePerCandle = chartWidth / CGFloat(candles.count)
        let bodyWidth = spacePerCandle * 0.75
        let calculatedWidth = max(bodyWidth / 3, 1)
        return .fixed(min(calculatedWidth, 4))
    }

    /// Time span of the data in hours
    private var dataTimeSpanHours: Double {
        guard let first = candles.first?.timestamp,
              let last = candles.last?.timestamp else { return 24 }
        return abs(last.timeIntervalSince(first)) / 3600
    }

    /// Simple Moving Average based on close prices (covers entire chart)
    /// Uses up to 20-period lookback, or whatever data is available for early points
    private var movingAverage: [(index: Int, value: Double)] {
        guard candles.count >= 2 else { return [] }
        let maxPeriod = 20

        var result: [(Int, Double)] = []
        for i in 0..<candles.count {
            // Use as many candles as available, up to maxPeriod
            let period = min(i + 1, maxPeriod)
            let startIndex = i - period + 1
            let slice = candles[startIndex...i]
            let avg = slice.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.close).doubleValue } / Double(period)
            result.append((i, avg))
        }
        return result
    }

    private var priceRange: ClosedRange<Double> {
        guard !candles.isEmpty else { return 0...100 }

        let allLows = candles.map { NSDecimalNumber(decimal: $0.low).doubleValue }
        let allHighs = candles.map { NSDecimalNumber(decimal: $0.high).doubleValue }

        let minPrice = allLows.min() ?? 0
        let maxPrice = allHighs.max() ?? 100

        // Add 5% padding
        let padding = (maxPrice - minPrice) * 0.05
        return (minPrice - padding)...(maxPrice + padding)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            chartContent
                .chartOverlay { proxy in
                    chartOverlayContent(proxy: proxy)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self),
                               index >= 0, index < candles.count {
                                Text(formatAxisDate(candles[index].timestamp))
                                    .font(Typography.caption2)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text(formatAxisPrice(price))
                                    .font(Typography.caption2)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                }
                .chartXScale(domain: -0.5...(Double(candles.count) - 0.5))
                .chartYScale(domain: priceRange)
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(
                            GridPattern()
                                .stroke(Color.textTertiary.opacity(0.15), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                        )
                }
                .onAppear {
                    chartWidth = geometry.size.width
                }
                .onChange(of: geometry.size.width) { _, newWidth in
                    chartWidth = newWidth
                }
        }
        .frame(height: 200)
        .padding(.vertical, 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Candlestick chart showing \(candles.count) candles")
        .accessibilityHint("Drag to explore price history")
        .onAppear {
            impactGenerator.prepare()
        }
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        Chart {
            // Simple Moving Average line (behind candles)
            ForEach(movingAverage, id: \.index) { point in
                LineMark(
                    x: .value("Index", point.index),
                    y: .value("SMA", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.textTertiary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1))
            }

            ForEach(indexedCandles, id: \.candle.id) { index, candle in
                // Wick (high-low line)
                RectangleMark(
                    x: .value("Index", index),
                    yStart: .value("Low", NSDecimalNumber(decimal: candle.low).doubleValue),
                    yEnd: .value("High", NSDecimalNumber(decimal: candle.high).doubleValue),
                    width: wickWidth
                )
                .foregroundStyle(candle.isGreen ? Color.profitGreen : Color.lossRed)

                // Body (open-close box)
                RectangleMark(
                    x: .value("Index", index),
                    yStart: .value("Open", NSDecimalNumber(decimal: candle.open).doubleValue),
                    yEnd: .value("Close", NSDecimalNumber(decimal: candle.close).doubleValue),
                    width: candleBodyWidth
                )
                .foregroundStyle(candle.isGreen ? Color.profitGreen : Color.lossRed)
            }

            // Selection crosshair
            if let selected = selectedCandle,
               let selectedIndex = candles.firstIndex(where: { $0.id == selected.id }) {
                // Vertical crosshair line
                RuleMark(x: .value("Selected", selectedIndex))
                    .foregroundStyle(Color.textSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                // Horizontal crosshair line
                RuleMark(y: .value("Close", NSDecimalNumber(decimal: selected.close).doubleValue))
                    .foregroundStyle(Color.textSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                // Point marker at intersection
                PointMark(
                    x: .value("Index", selectedIndex),
                    y: .value("Close", NSDecimalNumber(decimal: selected.close).doubleValue)
                )
                .symbol(.circle)
                .symbolSize(80)
                .foregroundStyle(selected.isGreen ? Color.profitGreen : Color.lossRed)
            }
        }
    }

    // MARK: - Chart Overlay

    private func chartOverlayContent(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            let plotFrame = proxy.plotFrame.map { geometry[$0] } ?? .zero

            ZStack {
                // Touch gesture layer
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Convert x position to index
                                if let index: Int = proxy.value(atX: value.location.x) {
                                    let clampedIndex = max(0, min(index, candles.count - 1))
                                    let candle = candles[clampedIndex]

                                    // Haptic feedback when moving to a new candle
                                    if candle.id != selectedCandle?.id {
                                        impactGenerator.impactOccurred()
                                    }

                                    selectedCandle = candle
                                    plotFrameSize = plotFrame.size

                                    // Store position for tooltip
                                    if let xPos = proxy.position(forX: clampedIndex),
                                       let yPos = proxy.position(forY: NSDecimalNumber(decimal: candle.close).doubleValue) {
                                        selectedCandlePosition = CGPoint(x: xPos, y: yPos)
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedCandle = nil
                                }
                            }
                    )

                // Tooltip overlay
                if let selected = selectedCandle {
                    candleTooltipOverlay(for: selected, in: plotFrame)
                }
            }
        }
    }

    // MARK: - Candle Tooltip Overlay

    @ViewBuilder
    private func candleTooltipOverlay(for candle: CandleDataPoint, in plotFrame: CGRect) -> some View {
        let tooltipWidth: CGFloat = 120
        let tooltipHeight: CGFloat = 80
        let verticalOffset: CGFloat = 12

        // Calculate x position with clamping
        let xPos = selectedCandlePosition.x
        let clampedX = min(max(xPos, tooltipWidth / 2), plotFrame.width - tooltipWidth / 2)

        // Determine if tooltip should be above or below point
        let yRatio = selectedCandlePosition.y / plotFrame.height
        let showBelow = yRatio < 0.35

        // Calculate y position
        let yPos = showBelow
            ? selectedCandlePosition.y + verticalOffset + tooltipHeight / 2
            : selectedCandlePosition.y - verticalOffset - tooltipHeight / 2

        CandleTooltip(candle: candle)
            .frame(width: tooltipWidth)
            .position(x: clampedX, y: yPos)
    }

    // MARK: - Axis Formatting

    /// Format date for X-axis labels based on time span
    private func formatAxisDate(_ date: Date) -> String {
        if dataTimeSpanHours <= 24 {
            // Short ranges: show time only "2:30 PM"
            return date.formatted(date: .omitted, time: .shortened)
        } else if dataTimeSpanHours <= 168 { // 7 days
            // Medium ranges: show weekday "Mon"
            return date.formatted(.dateTime.weekday(.abbreviated))
        } else {
            // Longer ranges: show date "Dec 5"
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    /// Format price for Y-axis labels (compact)
    private func formatAxisPrice(_ value: Double) -> String {
        let absValue = abs(value)

        if absValue >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if absValue >= 10_000 {
            return String(format: "$%.0fK", value / 1_000)
        } else if absValue >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
        } else if absValue >= 1 {
            return String(format: "$%.0f", value)
        } else if absValue >= 0.01 {
            return String(format: "$%.2f", value)
        } else {
            return String(format: "$%.4f", value)
        }
    }

}

// MARK: - Candle Tooltip

private struct CandleTooltip: View {
    let candle: CandleDataPoint

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.tiny) {
            // Date
            Text(formatTimestamp(candle.timestamp))
                .font(Typography.caption2)
                .foregroundColor(.textSecondary)

            // OHLC values
            HStack(spacing: Spacing.small) {
                VStack(alignment: .leading, spacing: 2) {
                    ohlcRow(label: "O", value: candle.open)
                    ohlcRow(label: "H", value: candle.high)
                }
                VStack(alignment: .leading, spacing: 2) {
                    ohlcRow(label: "L", value: candle.low)
                    ohlcRow(label: "C", value: candle.close, highlight: true)
                }
            }
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.tiny)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.small))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    private func ohlcRow(label: String, value: Decimal, highlight: Bool = false) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(Typography.caption2)
                .foregroundColor(.textTertiary)
            Text(Formatters.formatPrice(value))
                .font(Typography.caption2)
                .fontWeight(highlight ? .semibold : .regular)
                .foregroundColor(highlight ? (candle.isGreen ? .profitGreen : .lossRed) : .textPrimary)
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let now = Date()
        let hoursDiff = now.timeIntervalSince(date) / 3600

        if hoursDiff < 24 {
            return date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.large) {
        CandlestickChartView(candles: generateSampleCandles())
    }
    .padding()
    .background(Color.backgroundPrimary)
}

// MARK: - Preview Helpers

private func generateSampleCandles() -> [CandleDataPoint] {
    let basePrice: Double = 45000
    let now = Date()

    return (0..<20).map { i in
        let timestamp = now.addingTimeInterval(Double(-20 + i) * 3600 * 4) // 4-hour candles
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
