//
//  ChartComponents.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 21/7/25.
//

import SwiftUI
import Charts

// MARK: - Price Change Display

struct ChartPriceChangeView: View {
    let currentPrice: Double
    let priceChange: Double
    let priceChangePercent: Double
    let isPositive: Bool
    let flashColor: Color?
    let onPriceChange: ((Double) -> Void)?
    
    @State private var isFlashing = false
    
    init(currentPrice: Double, priceChange: Double, priceChangePercent: Double, flashColor: Color? = nil, onPriceChange: ((Double) -> Void)? = nil) {
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.priceChangePercent = priceChangePercent
        self.isPositive = priceChangePercent >= 0
        self.flashColor = flashColor
        self.onPriceChange = onPriceChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(CurrencyFormatter.formatCurrencyEnhanced(currentPrice))
                .font(.system(size: 36, weight: .bold, design: .default))
                .foregroundColor(isFlashing ? flashColor ?? .primary : .primary)
                .scaleEffect(isFlashing ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isFlashing)
                .onChange(of: currentPrice) { oldValue, newValue in
                    if oldValue != newValue && oldValue > 0 {
                        triggerFlash(oldPrice: oldValue, newPrice: newValue)
                        onPriceChange?(newValue)
                    }
                }
            
            HStack(spacing: 8) {
                let changeColor: Color = isPositive ? .green : .red
                let changePrefix = isPositive ? "+" : ""
                
                Text(changePrefix)
                    .foregroundColor(changeColor)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(CurrencyFormatter.formatCurrencyEnhanced(abs(priceChange)))
                    .foregroundColor(changeColor)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("(\(String(format: "%.2f", priceChangePercent))%) 24h")
                    .foregroundColor(changeColor)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
    
    private func triggerFlash(oldPrice: Double, newPrice: Double) {
        withAnimation(.easeInOut(duration: 0.15)) {
            isFlashing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.25)) {
                isFlashing = false
            }
        }
    }
}

// MARK: - Chart Type Selector

struct ChartTypeSelector: View {
    @Binding var selectedType: ChartDisplayType
    
    var body: some View {
        HStack {
            ForEach(ChartDisplayType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedType = type
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
                        selectedType == type ? Color.accentColor : Color(.systemGray5)
                    )
                    .foregroundColor(
                        selectedType == type ? .white : .primary
                    )
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Chart Header

struct ChartHeaderView: View {
    let currencyPair: CurrencyPair
    let selectedDataPoint: ChartData?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(currencyPair.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(selectedDataPoint.map { CurrencyFormatter.formatCurrencyEnhanced($0.close) } ?? CurrencyFormatter.formatCurrencyEnhanced(currencyPair.currentPrice))
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
                            
                            Text("\(currencyPair.isPositiveChange ? "+" : "")\(String(format: "%.2f", currencyPair.priceChangePercent24h))% 24h")
                                .foregroundColor(currencyPair.isPositiveChange ? .green : .red)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Chart Period Selector

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

// MARK: - Modern Stat Card

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

// MARK: - Statistics Card

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

// MARK: - Time Period Button

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

// MARK: - Chart Loading View

struct ChartLoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading chart data...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(height: ChartConfiguration.defaultHeight)
    }
}

// MARK: - Chart Empty View

struct ChartEmptyView: View {
    var body: some View {
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
        .frame(height: ChartConfiguration.defaultHeight)
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        
        return path
    }
}

// MARK: - Chart Statistics

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