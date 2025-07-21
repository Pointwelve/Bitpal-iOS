//
//  TechnicalIndicatorDetailView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import Charts

struct TechnicalIndicatorDetailView: View {
    let indicator: MarketAnalysisView.TechnicalIndicatorType
    let analysis: TechnicalAnalysis
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text(indicator.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Indicator specific content
                    indicatorContent
                }
                .padding(.bottom)
            }
            .navigationTitle("Technical Indicator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var indicatorContent: some View {
        switch indicator {
        case .movingAverages:
            movingAveragesDetail
        case .momentum:
            momentumDetail
        case .volatility:
            volatilityDetail
        case .volume:
            volumeDetail
        case .supportResistance:
            supportResistanceDetail
        }
    }
    
    private var movingAveragesDetail: some View {
        VStack(spacing: 20) {
            // Chart
            Chart {
                // SMA 20
                ForEach(Array(analysis.sma20.values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("SMA 20", value.value)
                    )
                    .foregroundStyle(.blue)
                }
                
                // SMA 50
                ForEach(Array(analysis.sma50.values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("SMA 50", value.value)
                    )
                    .foregroundStyle(.orange)
                }
                
                // SMA 200
                ForEach(Array(analysis.sma200.values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("SMA 200", value.value)
                    )
                    .foregroundStyle(.red)
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Values
            VStack(spacing: 12) {
                MovingAverageRow(
                    title: "SMA 20",
                    value: analysis.sma20.current ?? 0,
                    trend: analysis.sma20.trend,
                    color: .blue
                )
                
                MovingAverageRow(
                    title: "SMA 50",
                    value: analysis.sma50.current ?? 0,
                    trend: analysis.sma50.trend,
                    color: .orange
                )
                
                MovingAverageRow(
                    title: "SMA 200",
                    value: analysis.sma200.current ?? 0,
                    trend: analysis.sma200.trend,
                    color: .red
                )
                
                MovingAverageRow(
                    title: "EMA 12",
                    value: analysis.ema12.current ?? 0,
                    trend: analysis.ema12.trend,
                    color: .green
                )
                
                MovingAverageRow(
                    title: "EMA 26",
                    value: analysis.ema26.current ?? 0,
                    trend: analysis.ema26.trend,
                    color: .purple
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Signal interpretation
            SignalInterpretationCard(
                signal: analysis.getMASignal(),
                description: getMovingAverageDescription()
            )
            .padding(.horizontal)
        }
    }
    
    private var momentumDetail: some View {
        VStack(spacing: 20) {
            // RSI Chart
            Chart {
                ForEach(Array(analysis.rsi.values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("RSI", value.value)
                    )
                    .foregroundStyle(.blue)
                }
                
                // Overbought line (70)
                RuleMark(y: .value("Overbought", 70))
                    .foregroundStyle(.red.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                
                // Oversold line (30)
                RuleMark(y: .value("Oversold", 30))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // MACD Chart
            Chart {
                ForEach(Array(analysis.macd.macdLine.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("MACD", value.value)
                    )
                    .foregroundStyle(.blue)
                }
                
                ForEach(Array(analysis.macd.signalLine.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("Signal", value.value)
                    )
                    .foregroundStyle(.orange)
                }
                
                ForEach(Array(analysis.macd.histogram.enumerated()), id: \.offset) { index, value in
                    BarMark(
                        x: .value("Time", value.timestamp),
                        y: .value("Histogram", value.value)
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                }
            }
            .frame(height: 150)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Values
            VStack(spacing: 12) {
                MomentumIndicatorRow(
                    title: "RSI (14)",
                    value: analysis.rsi.current ?? 0,
                    signal: analysis.rsi.signal.rawValue.capitalized
                )
                
                MomentumIndicatorRow(
                    title: "MACD",
                    value: analysis.macd.currentMACD ?? 0,
                    signal: analysis.macd.crossoverSignal.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
                )
                
                MomentumIndicatorRow(
                    title: "Stochastic %K",
                    value: analysis.stochastic.currentK ?? 0,
                    signal: analysis.stochastic.signal.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var volatilityDetail: some View {
        VStack(spacing: 20) {
            // Bollinger Bands Chart
            Chart {
                ForEach(Array(analysis.bollingerBands.upperBand.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("Upper Band", value.value)
                    )
                    .foregroundStyle(.red)
                }
                
                ForEach(Array(analysis.bollingerBands.middleBand.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("Middle Band", value.value)
                    )
                    .foregroundStyle(.blue)
                }
                
                ForEach(Array(analysis.bollingerBands.lowerBand.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("Lower Band", value.value)
                    )
                    .foregroundStyle(.green)
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // ATR Chart
            Chart {
                ForEach(Array(analysis.atr.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("ATR", value.value)
                    )
                    .foregroundStyle(.purple)
                }
            }
            .frame(height: 150)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Values
            VStack(spacing: 12) {
                VolatilityIndicatorRow(
                    title: "Upper Band",
                    value: analysis.bollingerBands.currentUpper ?? 0
                )
                
                VolatilityIndicatorRow(
                    title: "Middle Band (SMA 20)",
                    value: analysis.bollingerBands.currentMiddle ?? 0
                )
                
                VolatilityIndicatorRow(
                    title: "Lower Band",
                    value: analysis.bollingerBands.currentLower ?? 0
                )
                
                VolatilityIndicatorRow(
                    title: "Average True Range",
                    value: analysis.atr.last?.value ?? 0
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var volumeDetail: some View {
        VStack(spacing: 20) {
            // Volume MA Chart
            Chart {
                ForEach(Array(analysis.volumeIndicators.volumeMA.values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("Volume MA", value.value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 150)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // OBV Chart
            Chart {
                ForEach(Array(analysis.volumeIndicators.onBalanceVolume.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Time", value.timestamp),
                        y: .value("OBV", value.value)
                    )
                    .foregroundStyle(.green)
                }
            }
            .frame(height: 150)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Values
            VStack(spacing: 12) {
                VolumeIndicatorRow(
                    title: "Volume Trend",
                    value: analysis.volumeIndicators.volumeTrend.rawValue.capitalized
                )
                
                VolumeIndicatorRow(
                    title: "Volume MA (20)",
                    value: "\(String(format: "%.0f", analysis.volumeIndicators.volumeMA.current ?? 0))"
                )
                
                VolumeIndicatorRow(
                    title: "On Balance Volume",
                    value: "\(String(format: "%.0f", analysis.volumeIndicators.onBalanceVolume.last?.value ?? 0))"
                )
                
                VolumeIndicatorRow(
                    title: "Volume RSI",
                    value: "\(String(format: "%.0f", analysis.volumeIndicators.volumeRSI.current ?? 0))"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var supportResistanceDetail: some View {
        VStack(spacing: 20) {
            // Support Levels
            VStack(spacing: 12) {
                Text("Support Levels")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if analysis.supportLevels.isEmpty {
                    Text("No support levels identified")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(analysis.supportLevels.prefix(5)) { level in
                        SupportResistanceRow(level: level)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Resistance Levels
            VStack(spacing: 12) {
                Text("Resistance Levels")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if analysis.resistanceLevels.isEmpty {
                    Text("No resistance levels identified")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(analysis.resistanceLevels.prefix(5)) { level in
                        SupportResistanceRow(level: level)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private func getMovingAverageDescription() -> String {
        let signal = analysis.getMASignal()
        switch signal {
        case .bullish:
            return "Moving averages are in bullish alignment. SMA20 > SMA50 > SMA200 indicates upward momentum."
        case .bearish:
            return "Moving averages are in bearish alignment. SMA20 < SMA50 < SMA200 indicates downward momentum."
        case .neutral:
            return "Moving averages are mixed. No clear directional bias from the moving average signals."
        }
    }
}

// MARK: - Supporting Views

struct MovingAverageRow: View {
    let title: String
    let value: Double
    let trend: TrendDirection
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("$\(String(format: "%.2f", value))")
                .font(.caption)
                .fontWeight(.medium)
            
            Image(systemName: trend == .bullish ? "arrow.up" : trend == .bearish ? "arrow.down" : "minus")
                .font(.caption2)
                .foregroundColor(trend == .bullish ? .green : trend == .bearish ? .red : .gray)
        }
    }
}

struct MomentumIndicatorRow: View {
    let title: String
    let value: Double
    let signal: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(signal)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(String(format: "%.2f", value))")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct VolatilityIndicatorRow: View {
    let title: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("$\(String(format: "%.2f", value))")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct VolumeIndicatorRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct SupportResistanceRow: View {
    let level: SupportResistanceLevel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("$\(String(format: "%.2f", level.price))")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Strength: \(String(format: "%.1f", level.strength))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(level.type.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(level.type == .support ? .green : .red)
                
                Text("Touches: \(level.touchCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SignalInterpretationCard: View {
    let signal: TechnicalSignal
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Signal Interpretation")
                    .font(.headline)
                
                Spacer()
                
                Text(signal.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(signal.color).opacity(0.2))
                    .foregroundColor(Color(signal.color))
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    // Sample technical analysis data
    let sampleAnalysis = TechnicalAnalysis(
        currencyPairId: "BTC-USD",
        timestamp: Date(),
        timeframe: .oneDay,
        sma20: MovingAverageData(period: 20, values: []),
        sma50: MovingAverageData(period: 50, values: []),
        sma200: MovingAverageData(period: 200, values: []),
        ema12: MovingAverageData(period: 12, values: []),
        ema26: MovingAverageData(period: 26, values: []),
        rsi: RSIData(period: 14, values: []),
        macd: MACDData(macdLine: [], signalLine: [], histogram: []),
        stochastic: StochasticData(kPercent: [], dPercent: []),
        bollingerBands: BollingerBandsData(upperBand: [], middleBand: [], lowerBand: []),
        atr: [],
        volumeIndicators: VolumeIndicators(
            volumeMA: MovingAverageData(period: 20, values: []),
            onBalanceVolume: [],
            volumeRSI: RSIData(period: 14, values: [])
        ),
        supportLevels: [],
        resistanceLevels: []
    )
    
    return TechnicalIndicatorDetailView(
        indicator: .movingAverages,
        analysis: sampleAnalysis
    )
}