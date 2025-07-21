//
//  MarketAnalysisView.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import SwiftUI
import SwiftData

struct MarketAnalysisView: View {
    let currencyPair: CurrencyPair
    
    @Environment(\.dismiss) private var dismiss
    @Environment(TechnicalAnalysisService.self) private var analysisService
    @State private var selectedTimeframe: ChartTimeframe = .oneDay
    @State private var analysis: MarketAnalysis?
    @State private var isLoading = false
    @State private var showingIndicatorDetail = false
    @State private var selectedIndicator: TechnicalIndicatorType?
    
    enum TechnicalIndicatorType: String, CaseIterable {
        case movingAverages = "Moving Averages"
        case momentum = "Momentum"
        case volatility = "Volatility"
        case volume = "Volume"
        case supportResistance = "Support & Resistance"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with currency info
                    headerSection
                    
                    // Timeframe selector
                    timeframeSelector
                    
                    if isLoading {
                        ProgressView("Analyzing market data...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let analysis = analysis {
                        // Overall recommendation
                        recommendationCard(analysis)
                        
                        // Technical indicators summary
                        technicalIndicatorsSection(analysis.technicalAnalysis)
                        
                        // Market sentiment
                        marketSentimentSection(analysis.marketSentiment)
                        
                        // Price targets
                        priceTargetsSection(analysis.priceTargets)
                        
                        // Risk assessment
                        riskAssessmentSection(analysis.riskAssessment)
                        
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Market Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await refreshAnalysis()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadAnalysis()
            }
            .sheet(isPresented: $showingIndicatorDetail) {
                if let indicator = selectedIndicator, let analysis = analysis {
                    TechnicalIndicatorDetailView(
                        indicator: indicator,
                        analysis: analysis.technicalAnalysis
                    )
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(currencyPair.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("$\(String(format: "%.2f", currencyPair.currentPrice))")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: currencyPair.isPositiveChange ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    
                    Text("\(String(format: "%.2f", currencyPair.priceChangePercent24h))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(currencyPair.isPositiveChange ? .green : .red)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                    Button {
                        selectedTimeframe = timeframe
                        Task {
                            await refreshAnalysis()
                        }
                    } label: {
                        Text(timeframe.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedTimeframe == timeframe 
                                    ? Color.accentColor 
                                    : Color(.systemGray5)
                            )
                            .foregroundColor(
                                selectedTimeframe == timeframe 
                                    ? .white 
                                    : .primary
                            )
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func recommendationCard(_ analysis: MarketAnalysis) -> some View {
        VStack(spacing: 12) {
            Text("Overall Recommendation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.recommendation.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(analysis.recommendation.color))
                    
                    Text("Signal Strength: \(analysis.technicalAnalysis.signalStrength.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: analysis.technicalAnalysis.signalStrength.progressValue,
                    color: Color(analysis.recommendation.color)
                )
                .frame(width: 60, height: 60)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func technicalIndicatorsSection(_ technical: TechnicalAnalysis) -> some View {
        VStack(spacing: 16) {
            Text("Technical Indicators")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(TechnicalIndicatorType.allCases, id: \.self) { indicator in
                    Button {
                        selectedIndicator = indicator
                        showingIndicatorDetail = true
                    } label: {
                        TechnicalIndicatorCard(
                            indicator: indicator,
                            analysis: technical
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func marketSentimentSection(_ sentiment: MarketSentiment) -> some View {
        VStack(spacing: 12) {
            Text("Market Sentiment")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                SentimentRow(title: "Fear & Greed Index", value: sentiment.fearGreedIndex / 100)
                SentimentRow(title: "Social Sentiment", value: (sentiment.socialSentiment + 1) / 2)
                SentimentRow(title: "News Impact", value: (sentiment.newsImpact + 1) / 2)
                SentimentRow(title: "Institutional Flow", value: (sentiment.institutionalFlow + 1) / 2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func priceTargetsSection(_ targets: [PriceTarget]) -> some View {
        VStack(spacing: 12) {
            Text("Price Targets")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(targets.prefix(5)) { target in
                PriceTargetRow(target: target, currentPrice: currencyPair.currentPrice)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func riskAssessmentSection(_ risk: RiskAssessment) -> some View {
        VStack(spacing: 12) {
            Text("Risk Assessment")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(risk.riskLevel.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(risk.riskLevel.color))
                    
                    Text("Max Drawdown: \(String(format: "%.1f", risk.maxDrawdown))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: risk.riskScore,
                    color: Color(risk.riskLevel.color)
                )
                .frame(width: 50, height: 50)
            }
            
            VStack(spacing: 6) {
                RiskFactorRow(title: "Volatility", value: risk.volatility)
                RiskFactorRow(title: "Liquidity Risk", value: risk.liquidityRisk)
                RiskFactorRow(title: "Correlation Risk", value: risk.correlationRisk)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Analysis Available")
                .font(.headline)
            
            Text("Tap refresh to analyze market data")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Analyze Now") {
                Task {
                    await refreshAnalysis()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func loadAnalysis() async {
        // Check for cached analysis first
        if let cached = analysisService.getCachedAnalysis(for: currencyPair.id) {
            analysis = cached
        } else {
            await refreshAnalysis()
        }
    }
    
    private func refreshAnalysis() async {
        isLoading = true
        
        do {
            let newAnalysis = try await analysisService.performTechnicalAnalysis(
                for: currencyPair,
                timeframe: selectedTimeframe
            )
            analysis = newAnalysis
        } catch {
            // Handle error - could show alert
        }
        
        isLoading = false
    }
}

struct TechnicalIndicatorCard: View {
    let indicator: MarketAnalysisView.TechnicalIndicatorType
    let analysis: TechnicalAnalysis
    
    var body: some View {
        VStack(spacing: 8) {
            Text(indicator.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            indicatorContent
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var indicatorContent: some View {
        switch indicator {
        case .movingAverages:
            VStack(spacing: 2) {
                Text(analysis.getMASignal().displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(analysis.getMASignal().color))
                
                Text("SMA 20: \(String(format: "%.2f", analysis.sma20.current ?? 0))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
        case .momentum:
            VStack(spacing: 2) {
                Text("RSI: \(String(format: "%.0f", analysis.rsi.current ?? 0))")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(analysis.rsi.signal.technicalSignal.color))
                
                Text(analysis.rsi.signal.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
        case .volatility:
            VStack(spacing: 2) {
                Text("Bollinger")
                    .font(.caption2)
                    .fontWeight(.semibold)
                
                Text("Bands")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
        case .volume:
            VStack(spacing: 2) {
                Text(analysis.volumeIndicators.volumeTrend.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.semibold)
                
                Text("Volume")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
        case .supportResistance:
            VStack(spacing: 2) {
                Text("\(analysis.supportLevels.count) / \(analysis.resistanceLevels.count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                
                Text("S/R Levels")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SentimentRow: View {
    let title: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            ProgressView(value: value)
                .frame(width: 60)
            
            Text("\(String(format: "%.0f", value * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 35, alignment: .trailing)
        }
    }
}

struct PriceTargetRow: View {
    let target: PriceTarget
    let currentPrice: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("$\(String(format: "%.2f", target.price))")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(target.rationale)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%+.1f", ((target.price - currentPrice) / currentPrice) * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(target.price > currentPrice ? .green : .red)
                
                Text("\(String(format: "%.0f", target.probability * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RiskFactorRow: View {
    let title: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            ProgressView(value: value)
                .frame(width: 50)
                .tint(value > 0.7 ? .red : value > 0.4 ? .orange : .green)
            
            Text("\(String(format: "%.0f", value * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(String(format: "%.0f", progress * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Extensions

extension TechnicalAnalysis {
    func getMASignal() -> TechnicalSignal {
        guard let sma20Current = sma20.current,
              let sma50Current = sma50.current,
              let sma200Current = sma200.current else { return .neutral }
        
        if sma50Current > sma200Current && sma20Current > sma50Current {
            return .bullish
        }
        
        if sma50Current < sma200Current && sma20Current < sma50Current {
            return .bearish
        }
        
        return .neutral
    }
}

extension SignalStrength {
    var progressValue: Double {
        switch self {
        case .strong: return 1.0
        case .moderate: return 0.75
        case .weak: return 0.5
        case .veryWeak: return 0.25
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CurrencyPair.self, configurations: config)
    
    let samplePair = CurrencyPair(
        baseCurrency: Currency.bitcoin(),
        quoteCurrency: Currency.usd(),
        exchange: Exchange.coinbase()
    )
    samplePair.currentPrice = 45000
    samplePair.priceChangePercent24h = 5.2
    
    return MarketAnalysisView(currencyPair: samplePair)
        .modelContainer(container)
        .environment(TechnicalAnalysisService.shared)
}