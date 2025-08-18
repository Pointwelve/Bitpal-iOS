//
//  ChartUtilities.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 21/7/25.
//

import Foundation
import SwiftUI

// MARK: - Chart Display Type

enum ChartDisplayType: String, CaseIterable, Hashable {
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

// MARK: - Chart Configuration

struct ChartConfiguration {
    static let defaultHeight: CGFloat = 300
    static let compactHeight: CGFloat = 280
    static let expandedHeight: CGFloat = 400
    
    static let maxDataPoints = 150
    static let maxCandlestickPoints = 80
    
    static let hapticThrottleInterval: TimeInterval = 0.1
    static let selectionDebounceInterval: TimeInterval = 0.016  // ~60fps
    
    static let tooltipPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
    static let horizontalPadding: CGFloat = 20
    
    // Period-specific optimization settings
    static func optimizedDataPoints(for period: String, chartType: ChartDisplayType) -> Int {
        let baseCount: Int
        switch period {
        case "15m":
            baseCount = chartType == .candlestick ? 45 : 60     // Consistent candle count with 1D
        case "1h":
            baseCount = chartType == .candlestick ? 45 : 70     // Consistent candle count with 1D
        case "4h":
            baseCount = chartType == .candlestick ? 48 : 80     // Consistent candle count with 1D
        case "1D":
            baseCount = chartType == .candlestick ? 48 : 96     // 30-minute intervals
        case "1W":
            baseCount = chartType == .candlestick ? 56 : 112    // 3-hour intervals
        case "1Y":
            baseCount = chartType == .candlestick ? 52 : 80     // Weekly intervals
        case "YTD":
            // Calculate based on days since January 1st
            let daysYTD = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            let ytdCount = min(60, max(30, daysYTD / 2)) // 2-day intervals, capped at 60
            baseCount = chartType == .candlestick ? ytdCount : ytdCount * 2
        default:
            baseCount = chartType == .candlestick ? maxCandlestickPoints : maxDataPoints
        }
        return min(baseCount, chartType == .candlestick ? maxCandlestickPoints : maxDataPoints)
    }
    
    static func decimationStrategy(for period: String) -> DecimationStrategy {
        switch period {
        case "15m", "1h", "4h", "1D":
            return .largestTriangleThreeBuckets  // High precision for short periods
        case "1W":
            return .largestTriangleThreeBuckets  // Balanced approach
        case "1Y", "YTD":
            return .uniform                      // Simple uniform for long periods
        default:
            return .largestTriangleThreeBuckets
        }
    }
}

enum DecimationStrategy {
    case uniform
    case largestTriangleThreeBuckets
}

// MARK: - Chart Data Processing

struct ChartDataProcessor {
    
    // MARK: - Data Optimization
    
    static func optimizeData(_ data: [ChartData], for chartType: ChartDisplayType, period: String = "1D") -> [ChartData] {
        let targetCount = ChartConfiguration.optimizedDataPoints(for: period, chartType: chartType)
        
        guard data.count > targetCount else { return data }
        
        let strategy = ChartConfiguration.decimationStrategy(for: period)
        
        switch strategy {
        case .largestTriangleThreeBuckets:
            return largestTriangleThreeBuckets(data: data, threshold: targetCount)
        case .uniform:
            return uniformDecimation(data: data, targetCount: targetCount)
        }
    }
    
    // Legacy method for backward compatibility
    static func optimizeData(_ data: [ChartData], for chartType: ChartDisplayType) -> [ChartData] {
        return optimizeData(data, for: chartType, period: "1D")
    }
    
    // MARK: - Chart Range Calculation
    
    static func calculateChartRange(for data: [ChartData], chartType: ChartDisplayType) -> (min: Double, max: Double) {
        let minPrice: Double
        let maxPrice: Double
        
        if chartType == .candlestick {
            minPrice = data.map(\.low).min() ?? 0
            maxPrice = data.map(\.high).max() ?? 1
        } else {
            minPrice = data.map(\.close).min() ?? 0
            maxPrice = data.map(\.close).max() ?? 1
        }
        
        let priceRange = maxPrice - minPrice
        let padding = priceRange * 0.1
        return (max(0, minPrice - padding), maxPrice + padding)
    }
    
    // MARK: - Data Point Search
    
    static func findClosestDataPoint(in data: [ChartData], to targetDate: Date) -> ChartData? {
        guard !data.isEmpty else { return nil }
        
        // Use binary search for better performance with large datasets
        if data.count > 50 {
            return binarySearchClosest(in: data, target: targetDate)
        } else {
            // Linear search for small datasets
            return data.min { first, second in
                abs(first.date.timeIntervalSince(targetDate)) < abs(second.date.timeIntervalSince(targetDate))
            }
        }
    }
    
    // MARK: - Sample Data Generation
    
    static func generateSampleChartData(basePrice: Double, dataPoints: Int = 24) -> [ChartData] {
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
    
    // MARK: - Private Helper Methods
    
    private static func uniformDecimation(data: [ChartData], targetCount: Int) -> [ChartData] {
        guard data.count > targetCount else { return data }
        
        let step = Double(data.count) / Double(targetCount)
        var result: [ChartData] = []
        result.reserveCapacity(targetCount)
        
        result.append(data[0])
        
        for i in 1..<(targetCount - 1) {
            let index = Int(Double(i) * step)
            if index < data.count {
                result.append(data[index])
            }
        }
        
        if data.count > 1 {
            result.append(data[data.count - 1])
        }
        
        return result
    }
    
    private static func largestTriangleThreeBuckets(data: [ChartData], threshold: Int) -> [ChartData] {
        guard data.count > threshold, threshold > 2 else { return data }
        
        var result: [ChartData] = []
        let bucketSize = Double(data.count - 2) / Double(threshold - 2)
        
        result.append(data.first!)
        
        var a = 0
        
        for i in 0..<(threshold - 2) {
            let avgRangeStart = Int(Double(i + 1) * bucketSize) + 1
            let avgRangeEnd = min(Int(Double(i + 2) * bucketSize) + 1, data.count)
            
            var avgX: Double = 0
            var avgY: Double = 0
            var avgRangeLength = 0
            
            for j in avgRangeStart..<avgRangeEnd {
                avgX += data[j].date.timeIntervalSince1970
                avgY += data[j].close
                avgRangeLength += 1
            }
            
            if avgRangeLength > 0 {
                avgX /= Double(avgRangeLength)
                avgY /= Double(avgRangeLength)
            }
            
            let rangeStart = Int(Double(i) * bucketSize) + 1
            let rangeEnd = min(Int(Double(i + 1) * bucketSize) + 1, data.count)
            
            var maxArea: Double = 0
            var maxAreaPoint = rangeStart
            
            for j in rangeStart..<rangeEnd {
                let pointAX = data[a].date.timeIntervalSince1970
                let pointAY = data[a].close
                let pointBX = data[j].date.timeIntervalSince1970
                let pointBY = data[j].close
                
                let area = abs((pointAX - avgX) * (pointBY - avgY) - (pointAY - avgY) * (pointBX - avgX)) * 0.5
                
                if area > maxArea {
                    maxArea = area
                    maxAreaPoint = j
                }
            }
            
            result.append(data[maxAreaPoint])
            a = maxAreaPoint
        }
        
        result.append(data.last!)
        return result
    }
    
    private static func binarySearchClosest(in sortedData: [ChartData], target: Date) -> ChartData? {
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
}

// MARK: - Chart Styling

struct ChartStyling {
    
    static func chartLineColor(for data: [ChartData], colorScheme: ColorScheme) -> Color {
        if let first = data.first, let last = data.last {
            return last.close >= first.close ? .green : .red
        }
        return colorScheme == .dark ? .white : .blue
    }
    
    static func chartAreaGradient(lineColor: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                lineColor.opacity(0.4),
                lineColor.opacity(0.1),
                lineColor.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static func axisLabelColor(colorScheme: ColorScheme) -> Color {
        (colorScheme == .dark ? Color.white : Color.primary).opacity(0.7)
    }
    
    static func backgroundColor(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black : Color(.systemGroupedBackground)
    }
    
    static func primaryTextColor(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .primary
    }
}