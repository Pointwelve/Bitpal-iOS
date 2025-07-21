//
//  TechnicalAnalysisService.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class TechnicalAnalysisService {
    static let shared = TechnicalAnalysisService()
    
    private(set) var currentAnalysis: [String: MarketAnalysis] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    private var modelContext: ModelContext?
    private let apiClient = APIClient.shared
    private let historicalDataService = HistoricalDataService.shared
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        historicalDataService.setModelContext(context)
    }
    
    // MARK: - Public API
    
    func performTechnicalAnalysis(for currencyPair: CurrencyPair, timeframe: ChartTimeframe = .oneDay) async throws -> MarketAnalysis {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Fetch historical data needed for analysis
            let historicalData = try await fetchHistoricalDataForAnalysis(currencyPair: currencyPair, timeframe: timeframe)
            
            // Calculate technical indicators
            let technicalAnalysis = await calculateTechnicalAnalysis(
                currencyPairId: currencyPair.id,
                historicalData: historicalData,
                timeframe: timeframe
            )
            
            // Analyze market sentiment
            let marketSentiment = await analyzeMarketSentiment(for: currencyPair)
            
            // Generate price targets
            let priceTargets = generatePriceTargets(
                currentPrice: currencyPair.currentPrice,
                technicalAnalysis: technicalAnalysis
            )
            
            // Assess risk
            let riskAssessment = calculateRiskAssessment(
                historicalData: historicalData,
                technicalAnalysis: technicalAnalysis
            )
            
            // Combine into market analysis
            let analysis = MarketAnalysis(
                currencyPairId: currencyPair.id,
                timestamp: Date(),
                technicalAnalysis: technicalAnalysis,
                marketSentiment: marketSentiment,
                priceTargets: priceTargets,
                riskAssessment: riskAssessment
            )
            
            // Cache the analysis
            currentAnalysis[currencyPair.id] = analysis
            
            return analysis
            
        } catch {
            errorMessage = "Failed to perform technical analysis: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getCachedAnalysis(for currencyPairId: String) -> MarketAnalysis? {
        return currentAnalysis[currencyPairId]
    }
    
    func refreshAnalysis(for currencyPair: CurrencyPair, timeframe: ChartTimeframe = .oneDay) async {
        do {
            _ = try await performTechnicalAnalysis(for: currencyPair, timeframe: timeframe)
        } catch {
            // Error already set in performTechnicalAnalysis
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func fetchHistoricalDataForAnalysis(currencyPair: CurrencyPair, timeframe: ChartTimeframe) async throws -> [ChartData] {
        let _ = getDataLimitForTimeframe(timeframe)
        
        return try await historicalDataService.loadHistoricalData(
            for: currencyPair,
            period: timeframe.toChartPeriod(),
            forceRefresh: true
        )
    }
    
    private func getDataLimitForTimeframe(_ timeframe: ChartTimeframe) -> Int {
        switch timeframe {
        case .oneMinute, .fiveMinutes: return 500
        case .fifteenMinutes, .thirtyMinutes: return 400
        case .oneHour, .fourHours: return 300
        case .oneDay: return 200
        case .oneWeek, .oneMonth: return 100
        }
    }
    
    private func calculateTechnicalAnalysis(
        currencyPairId: String,
        historicalData: [ChartData],
        timeframe: ChartTimeframe
    ) async -> TechnicalAnalysis {
        let prices = historicalData.map { $0.close }
        let volumes = historicalData.map { $0.volume }
        let highs = historicalData.map { $0.high }
        let lows = historicalData.map { $0.low }
        let timestamps = historicalData.map { $0.date }
        
        // Calculate Moving Averages
        let sma20 = calculateSMA(prices: prices, period: 20, timestamps: timestamps)
        let sma50 = calculateSMA(prices: prices, period: 50, timestamps: timestamps)
        let sma200 = calculateSMA(prices: prices, period: 200, timestamps: timestamps)
        let ema12 = calculateEMA(prices: prices, period: 12, timestamps: timestamps)
        let ema26 = calculateEMA(prices: prices, period: 26, timestamps: timestamps)
        
        // Calculate Momentum Indicators
        let rsi = calculateRSI(prices: prices, period: 14, timestamps: timestamps)
        let macd = calculateMACD(prices: prices, timestamps: timestamps)
        let stochastic = calculateStochastic(highs: highs, lows: lows, closes: prices, timestamps: timestamps)
        
        // Calculate Volatility Indicators
        let bollingerBands = calculateBollingerBands(prices: prices, period: 20, timestamps: timestamps)
        let atr = calculateATR(highs: highs, lows: lows, closes: prices, period: 14, timestamps: timestamps)
        
        // Calculate Volume Indicators
        let volumeIndicators = calculateVolumeIndicators(prices: prices, volumes: volumes, timestamps: timestamps)
        
        // Calculate Support and Resistance
        let (supportLevels, resistanceLevels) = calculateSupportResistance(
            highs: highs,
            lows: lows,
            closes: prices,
            timeframe: timeframe
        )
        
        return TechnicalAnalysis(
            currencyPairId: currencyPairId,
            timestamp: Date(),
            timeframe: timeframe,
            sma20: sma20,
            sma50: sma50,
            sma200: sma200,
            ema12: ema12,
            ema26: ema26,
            rsi: rsi,
            macd: macd,
            stochastic: stochastic,
            bollingerBands: bollingerBands,
            atr: atr,
            volumeIndicators: volumeIndicators,
            supportLevels: supportLevels,
            resistanceLevels: resistanceLevels
        )
    }
    
    private func analyzeMarketSentiment(for currencyPair: CurrencyPair) async -> MarketSentiment {
        // In a real implementation, this would fetch sentiment data from various sources
        // For now, we'll simulate basic sentiment analysis
        
        let fearGreedIndex = Double.random(in: 0...100)
        let socialSentiment = Double.random(in: -1...1)
        let newsImpact = Double.random(in: -1...1)
        let institutionalFlow = Double.random(in: -1...1)
        
        return MarketSentiment(
            fearGreedIndex: fearGreedIndex,
            socialSentiment: socialSentiment,
            newsImpact: newsImpact,
            institutionalFlow: institutionalFlow
        )
    }
    
    private func generatePriceTargets(currentPrice: Double, technicalAnalysis: TechnicalAnalysis) -> [PriceTarget] {
        var targets: [PriceTarget] = []
        
        // Add resistance levels as upside targets
        for resistance in technicalAnalysis.resistanceLevels.prefix(3) {
            targets.append(PriceTarget(
                price: resistance.price,
                probability: resistance.strength,
                timeframe: .shortTerm,
                type: .resistance,
                rationale: "Technical resistance at \(String(format: "%.2f", resistance.price))"
            ))
        }
        
        // Add support levels as downside targets
        for support in technicalAnalysis.supportLevels.prefix(3) {
            targets.append(PriceTarget(
                price: support.price,
                probability: support.strength,
                timeframe: .shortTerm,
                type: .support,
                rationale: "Technical support at \(String(format: "%.2f", support.price))"
            ))
        }
        
        // Add Fibonacci targets
        let fibTargets = calculateFibonacciTargets(currentPrice: currentPrice, technicalAnalysis: technicalAnalysis)
        targets.append(contentsOf: fibTargets)
        
        return targets.sorted { $0.probability > $1.probability }
    }
    
    private func calculateFibonacciTargets(currentPrice: Double, technicalAnalysis: TechnicalAnalysis) -> [PriceTarget] {
        let fibLevels = [0.236, 0.382, 0.5, 0.618, 0.786]
        var targets: [PriceTarget] = []
        
        if let recentHigh = technicalAnalysis.resistanceLevels.first?.price,
           let recentLow = technicalAnalysis.supportLevels.first?.price {
            
            let range = recentHigh - recentLow
            
            for level in fibLevels {
                let retracementPrice = recentHigh - (range * level)
                let extensionPrice = recentHigh + (range * level)
                
                targets.append(PriceTarget(
                    price: retracementPrice,
                    probability: 0.6,
                    timeframe: .mediumTerm,
                    type: .fibonacci,
                    rationale: "Fibonacci \(Int(level * 100))% retracement"
                ))
                
                targets.append(PriceTarget(
                    price: extensionPrice,
                    probability: 0.4,
                    timeframe: .longTerm,
                    type: .fibonacci,
                    rationale: "Fibonacci \(Int(level * 100))% extension"
                ))
            }
        }
        
        return targets
    }
    
    private func calculateRiskAssessment(historicalData: [ChartData], technicalAnalysis: TechnicalAnalysis) -> RiskAssessment {
        let returns = calculateReturns(from: historicalData.map { $0.close })
        let volatility = calculateVolatility(returns: returns)
        let maxDrawdown = calculateMaxDrawdown(prices: historicalData.map { $0.close })
        
        return RiskAssessment(
            volatility: min(volatility / 0.5, 1.0), // Normalize to 0-1
            liquidityRisk: 0.3, // Placeholder - would use volume/spread analysis
            correlationRisk: 0.2, // Placeholder - would analyze correlation with market
            maxDrawdown: maxDrawdown
        )
    }
    
    // MARK: - Technical Indicator Calculations
    
    private func calculateSMA(prices: [Double], period: Int, timestamps: [Date]) -> MovingAverageData {
        var values: [TechnicalIndicatorValue] = []
        
        for i in (period - 1)..<prices.count {
            let slice = Array(prices[i - period + 1...i])
            let average = slice.reduce(0, +) / Double(slice.count)
            
            values.append(TechnicalIndicatorValue(
                timestamp: timestamps[i],
                value: average,
                signal: nil
            ))
        }
        
        return MovingAverageData(period: period, values: values)
    }
    
    private func calculateEMA(prices: [Double], period: Int, timestamps: [Date]) -> MovingAverageData {
        var values: [TechnicalIndicatorValue] = []
        let multiplier = 2.0 / Double(period + 1)
        
        if prices.count >= period {
            // Initialize with SMA
            let initialSMA = Array(prices[0..<period]).reduce(0, +) / Double(period)
            var ema = initialSMA
            
            values.append(TechnicalIndicatorValue(
                timestamp: timestamps[period - 1],
                value: ema,
                signal: nil
            ))
            
            // Calculate EMA for remaining values
            for i in period..<prices.count {
                ema = ((prices[i] - ema) * multiplier) + ema
                values.append(TechnicalIndicatorValue(
                    timestamp: timestamps[i],
                    value: ema,
                    signal: nil
                ))
            }
        }
        
        return MovingAverageData(period: period, values: values)
    }
    
    private func calculateRSI(prices: [Double], period: Int, timestamps: [Date]) -> RSIData {
        var gains: [Double] = []
        var losses: [Double] = []
        var values: [TechnicalIndicatorValue] = []
        
        // Calculate price changes
        for i in 1..<prices.count {
            let change = prices[i] - prices[i - 1]
            gains.append(max(change, 0))
            losses.append(max(-change, 0))
        }
        
        // Calculate RSI
        for i in (period - 1)..<gains.count {
            let avgGain = Array(gains[i - period + 1...i]).reduce(0, +) / Double(period)
            let avgLoss = Array(losses[i - period + 1...i]).reduce(0, +) / Double(period)
            
            let rs = avgLoss == 0 ? 100 : avgGain / avgLoss
            let rsi = 100 - (100 / (1 + rs))
            
            values.append(TechnicalIndicatorValue(
                timestamp: timestamps[i + 1],
                value: rsi,
                signal: nil
            ))
        }
        
        return RSIData(period: period, values: values)
    }
    
    private func calculateMACD(prices: [Double], timestamps: [Date]) -> MACDData {
        let ema12 = calculateEMA(prices: prices, period: 12, timestamps: timestamps)
        let ema26 = calculateEMA(prices: prices, period: 26, timestamps: timestamps)
        
        var macdLine: [TechnicalIndicatorValue] = []
        let startIndex = max(ema12.values.count, ema26.values.count) - min(ema12.values.count, ema26.values.count)
        
        // Calculate MACD line
        for i in 0..<min(ema12.values.count, ema26.values.count) {
            let macdValue = ema12.values[i + startIndex].value - ema26.values[i].value
            macdLine.append(TechnicalIndicatorValue(
                timestamp: ema12.values[i + startIndex].timestamp,
                value: macdValue,
                signal: nil
            ))
        }
        
        // Calculate signal line (9-period EMA of MACD)
        let macdPrices = macdLine.map { $0.value }
        let macdTimestamps = macdLine.map { $0.timestamp }
        let signalEMA = calculateEMA(prices: macdPrices, period: 9, timestamps: macdTimestamps)
        
        // Calculate histogram
        var histogram: [TechnicalIndicatorValue] = []
        for i in 0..<min(macdLine.count, signalEMA.values.count) {
            let histValue = macdLine[i].value - signalEMA.values[i].value
            histogram.append(TechnicalIndicatorValue(
                timestamp: macdLine[i].timestamp,
                value: histValue,
                signal: nil
            ))
        }
        
        return MACDData(
            macdLine: macdLine,
            signalLine: signalEMA.values,
            histogram: histogram
        )
    }
    
    private func calculateStochastic(highs: [Double], lows: [Double], closes: [Double], timestamps: [Date]) -> StochasticData {
        let period = 14
        var kPercent: [TechnicalIndicatorValue] = []
        
        for i in (period - 1)..<closes.count {
            let periodHighs = Array(highs[i - period + 1...i])
            let periodLows = Array(lows[i - period + 1...i])
            
            let highestHigh = periodHighs.max() ?? 0
            let lowestLow = periodLows.min() ?? 0
            
            let k = lowestLow == highestHigh ? 50 : ((closes[i] - lowestLow) / (highestHigh - lowestLow)) * 100
            
            kPercent.append(TechnicalIndicatorValue(
                timestamp: timestamps[i],
                value: k,
                signal: nil
            ))
        }
        
        // Calculate %D (3-period SMA of %K)
        let kValues = kPercent.map { $0.value }
        let kTimestamps = kPercent.map { $0.timestamp }
        let dPercent = calculateSMA(prices: kValues, period: 3, timestamps: kTimestamps)
        
        return StochasticData(kPercent: kPercent, dPercent: dPercent.values)
    }
    
    private func calculateBollingerBands(prices: [Double], period: Int, timestamps: [Date]) -> BollingerBandsData {
        let sma = calculateSMA(prices: prices, period: period, timestamps: timestamps)
        var upperBand: [TechnicalIndicatorValue] = []
        var lowerBand: [TechnicalIndicatorValue] = []
        
        for i in 0..<sma.values.count {
            let startIndex = (period - 1) + i
            let slice = Array(prices[startIndex - period + 1...startIndex])
            
            let mean = sma.values[i].value
            let variance = slice.map { pow($0 - mean, 2) }.reduce(0, +) / Double(slice.count)
            let stdDev = sqrt(variance)
            
            upperBand.append(TechnicalIndicatorValue(
                timestamp: sma.values[i].timestamp,
                value: mean + (2 * stdDev),
                signal: nil
            ))
            
            lowerBand.append(TechnicalIndicatorValue(
                timestamp: sma.values[i].timestamp,
                value: mean - (2 * stdDev),
                signal: nil
            ))
        }
        
        return BollingerBandsData(
            upperBand: upperBand,
            middleBand: sma.values,
            lowerBand: lowerBand
        )
    }
    
    private func calculateATR(highs: [Double], lows: [Double], closes: [Double], period: Int, timestamps: [Date]) -> [TechnicalIndicatorValue] {
        var trueRanges: [Double] = []
        var atrValues: [TechnicalIndicatorValue] = []
        
        // Calculate True Range
        for i in 1..<closes.count {
            let tr1 = highs[i] - lows[i]
            let tr2 = abs(highs[i] - closes[i - 1])
            let tr3 = abs(lows[i] - closes[i - 1])
            let trueRange = max(tr1, max(tr2, tr3))
            trueRanges.append(trueRange)
        }
        
        // Calculate ATR
        for i in (period - 1)..<trueRanges.count {
            let atr = Array(trueRanges[i - period + 1...i]).reduce(0, +) / Double(period)
            atrValues.append(TechnicalIndicatorValue(
                timestamp: timestamps[i + 1],
                value: atr,
                signal: nil
            ))
        }
        
        return atrValues
    }
    
    private func calculateVolumeIndicators(prices: [Double], volumes: [Double], timestamps: [Date]) -> VolumeIndicators {
        let volumeMA = calculateSMA(prices: volumes, period: 20, timestamps: timestamps)
        
        // On Balance Volume
        var obv: [TechnicalIndicatorValue] = []
        var obvValue = 0.0
        
        for i in 1..<prices.count {
            if prices[i] > prices[i - 1] {
                obvValue += volumes[i]
            } else if prices[i] < prices[i - 1] {
                obvValue -= volumes[i]
            }
            
            obv.append(TechnicalIndicatorValue(
                timestamp: timestamps[i],
                value: obvValue,
                signal: nil
            ))
        }
        
        // Volume RSI
        let volumeRSI = calculateRSI(prices: volumes, period: 14, timestamps: timestamps)
        
        return VolumeIndicators(
            volumeMA: volumeMA,
            onBalanceVolume: obv,
            volumeRSI: volumeRSI
        )
    }
    
    private func calculateSupportResistance(highs: [Double], lows: [Double], closes: [Double], timeframe: ChartTimeframe) -> ([SupportResistanceLevel], [SupportResistanceLevel]) {
        let lookback = min(50, closes.count)
        let recent = closes.suffix(lookback)
        let recentHighs = highs.suffix(lookback)
        let recentLows = lows.suffix(lookback)
        
        var supportLevels: [SupportResistanceLevel] = []
        var resistanceLevels: [SupportResistanceLevel] = []
        
        // Find local peaks and troughs
        for i in 2..<(lookback - 2) {
            let _ = Array(recent)[i]
            let currentHigh = Array(recentHighs)[i]
            let currentLow = Array(recentLows)[i]
            
            // Check for resistance (local high)
            if currentHigh > Array(recentHighs)[i-1] && currentHigh > Array(recentHighs)[i+1] &&
               currentHigh > Array(recentHighs)[i-2] && currentHigh > Array(recentHighs)[i+2] {
                
                resistanceLevels.append(SupportResistanceLevel(
                    price: currentHigh,
                    strength: 0.7,
                    touchCount: 1,
                    type: .resistance,
                    timeframe: timeframe
                ))
            }
            
            // Check for support (local low)
            if currentLow < Array(recentLows)[i-1] && currentLow < Array(recentLows)[i+1] &&
               currentLow < Array(recentLows)[i-2] && currentLow < Array(recentLows)[i+2] {
                
                supportLevels.append(SupportResistanceLevel(
                    price: currentLow,
                    strength: 0.7,
                    touchCount: 1,
                    type: .support,
                    timeframe: timeframe
                ))
            }
        }
        
        return (supportLevels.sorted { $0.price > $1.price }, resistanceLevels.sorted { $0.price < $1.price })
    }
    
    // MARK: - Utility Methods
    
    private func calculateReturns(from prices: [Double]) -> [Double] {
        var returns: [Double] = []
        for i in 1..<prices.count {
            let returnValue = (prices[i] - prices[i-1]) / prices[i-1]
            returns.append(returnValue)
        }
        return returns
    }
    
    private func calculateVolatility(returns: [Double]) -> Double {
        guard !returns.isEmpty else { return 0 }
        
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)
        return sqrt(variance) * sqrt(252) // Annualized volatility
    }
    
    private func calculateMaxDrawdown(prices: [Double]) -> Double {
        var maxDrawdown = 0.0
        var peak = prices[0]
        
        for price in prices {
            if price > peak {
                peak = price
            }
            
            let drawdown = (peak - price) / peak
            if drawdown > maxDrawdown {
                maxDrawdown = drawdown
            }
        }
        
        return maxDrawdown * 100 // Return as percentage
    }
}

// MARK: - Extensions

extension ChartTimeframe {
    func toChartPeriod() -> ChartPeriod {
        switch self {
        case .oneMinute: return .oneMinute
        case .fiveMinutes: return .fiveMinutes
        case .fifteenMinutes: return .fifteenMinutes
        case .thirtyMinutes: return .thirtyMinutes
        case .oneHour: return .oneHour
        case .fourHours: return .fourHours
        case .oneDay: return .oneDay
        case .oneWeek: return .oneWeek
        case .oneMonth: return .oneMonth
        }
    }
}