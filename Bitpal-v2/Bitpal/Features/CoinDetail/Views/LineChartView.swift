//
//  LineChartView.swift
//  Bitpal
//
//  Created by Bitpal Development on 12/1/25.
//

import SwiftUI
import Charts

/// Line chart view for displaying price history
/// Liquid Glass design with gradient fill and touch interaction
/// Per Constitution Principle I: Performance optimized with limited data points
struct LineChartView: View {
    // MARK: - Properties

    let dataPoints: [ChartDataPoint]
    let isPositive: Bool

    // MARK: - Touch Interaction State

    @State private var selectedPoint: ChartDataPoint?

    // MARK: - Computed Properties

    private var chartColor: Color {
        isPositive ? .profitGreen : .lossRed
    }

    /// Data point with highest price
    private var highPoint: ChartDataPoint? {
        dataPoints.max(by: { $0.price < $1.price })
    }

    /// Data point with lowest price
    private var lowPoint: ChartDataPoint? {
        dataPoints.min(by: { $0.price < $1.price })
    }

    // MARK: - Body

    var body: some View {
        chartContent
            .chartOverlay { proxy in
                chartOverlayContent(proxy: proxy)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartPlotStyle { plotArea in
                plotArea
                    .background(
                        GridPattern()
                            .stroke(Color.textTertiary.opacity(0.15), style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                    )
            }
            .frame(height: 200)
            .padding(.vertical, 20) // Reserve space for high/low price labels
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Interactive price chart showing \(dataPoints.count) data points")
            .accessibilityHint("Drag to explore price history. " + (isPositive ? "Price trending up" : "Price trending down"))
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Price", NSDecimalNumber(decimal: point.price).doubleValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            if let selected = selectedPoint {
                RuleMark(x: .value("Selected", selected.timestamp))
                    .foregroundStyle(chartColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Time", selected.timestamp),
                    y: .value("Price", NSDecimalNumber(decimal: selected.price).doubleValue)
                )
                .symbol(.circle)
                .symbolSize(80)
                .foregroundStyle(chartColor)
                .annotation(position: .top, alignment: .center, spacing: Spacing.small) {
                    SelectionTooltip(
                        price: selected.price,
                        timestamp: selected.timestamp,
                        chartColor: chartColor
                    )
                }
            }
        }
    }

    // MARK: - Chart Overlay

    private func chartOverlayContent(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            let plotFrame = proxy.plotFrame.map { geometry[$0] } ?? .zero

            ZStack {
                // High/Low labels
                labelsOverlay(proxy: proxy, plotFrame: plotFrame)

                // Touch gesture layer
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if let date: Date = proxy.value(atX: value.location.x) {
                                    selectedPoint = findNearestPoint(to: date)
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedPoint = nil
                                }
                            }
                    )
            }
        }
    }

    // MARK: - Labels Overlay

    @ViewBuilder
    private func labelsOverlay(proxy: ChartProxy, plotFrame: CGRect) -> some View {
        let labelWidth: CGFloat = 80

        // High price label
        if let high = highPoint, selectedPoint == nil,
           let xPos = proxy.position(forX: high.timestamp),
           let yPos = proxy.position(forY: NSDecimalNumber(decimal: high.price).doubleValue) {
            let clampedX = min(max(xPos, labelWidth / 2), plotFrame.width - labelWidth / 2)

            priceLabel(price: high.price)
                .position(x: clampedX, y: yPos - 16)
        }

        // Low price label
        if let low = lowPoint, selectedPoint == nil,
           let xPos = proxy.position(forX: low.timestamp),
           let yPos = proxy.position(forY: NSDecimalNumber(decimal: low.price).doubleValue) {
            let clampedX = min(max(xPos, labelWidth / 2), plotFrame.width - labelWidth / 2)

            priceLabel(price: low.price)
                .position(x: clampedX, y: yPos + 16)
        }
    }

    private func priceLabel(price: Decimal) -> some View {
        Text(Formatters.formatPrice(price))
            .font(Typography.caption)
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.backgroundPrimary.opacity(0.8))
            .cornerRadius(4)
    }

    // MARK: - Touch Interaction Helpers

    /// Find the nearest data point to a given date
    private func findNearestPoint(to targetDate: Date) -> ChartDataPoint? {
        dataPoints.min { point1, point2 in
            abs(targetDate.timeIntervalSince(point1.timestamp)) <
            abs(targetDate.timeIntervalSince(point2.timestamp))
        }
    }
}

// MARK: - Selection Tooltip

/// Tooltip view for displaying selected price point with Liquid Glass styling
private struct SelectionTooltip: View {
    let price: Decimal
    let timestamp: Date
    let chartColor: Color

    var body: some View {
        VStack(alignment: .center, spacing: Spacing.tiny) {
            Text(Formatters.formatPrice(price))
                .font(Typography.numericCaption)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)

            Text(formatTimestamp(timestamp))
                .font(Typography.caption2)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.tiny)
        .background(Color.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.small))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    /// Format timestamp based on recency
    private func formatTimestamp(_ date: Date) -> String {
        let now = Date()
        let hoursDiff = now.timeIntervalSince(date) / 3600

        if hoursDiff < 24 {
            // Within 24 hours: show time only
            return date.formatted(date: .omitted, time: .shortened)
        } else {
            // Older: show date and time
            return date.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

// MARK: - Grid Pattern

/// Dotted grid pattern for chart background
struct GridPattern: Shape {
    let rows: Int = 4
    let columns: Int = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let rowHeight = rect.height / CGFloat(rows)
        let columnWidth = rect.width / CGFloat(columns)

        // Horizontal lines
        for i in 1..<rows {
            let y = CGFloat(i) * rowHeight
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        // Vertical lines
        for i in 1..<columns {
            let x = CGFloat(i) * columnWidth
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.large) {
        // Positive trend
        LineChartView(
            dataPoints: generateSampleData(trend: .up),
            isPositive: true
        )
        .padding()

        // Negative trend
        LineChartView(
            dataPoints: generateSampleData(trend: .down),
            isPositive: false
        )
        .padding()
    }
    .background(Color.backgroundPrimary)
}

// MARK: - Preview Helpers

private enum Trend { case up, down }

private func generateSampleData(trend: Trend) -> [ChartDataPoint] {
    let basePrice: Double = 45000
    let now = Date()

    return (0..<24).map { hour in
        let timestamp = now.addingTimeInterval(Double(-24 + hour) * 3600)
        let variance = Double.random(in: -500...500)
        let trendOffset = trend == .up
            ? Double(hour) * 50
            : Double(24 - hour) * 50
        let price = Decimal(basePrice + trendOffset + variance)
        return ChartDataPoint(timestamp: timestamp, price: price)
    }
}
