//
//  TechnicalIndicators.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

// MARK: - Technical Indicator Models

struct TechnicalIndicatorValue: Codable, Sendable {
    let timestamp: Date
    let value: Double
    let signal: TechnicalSignal?
}

struct MovingAverageData: Codable, Sendable {
    let period: Int
    let values: [TechnicalIndicatorValue]
    
    var current: Double? {
        values.last?.value
    }
    
    var trend: TrendDirection {
        guard values.count >= 2 else { return .neutral }
        let recent = values.suffix(2).map { $0.value }
        return recent[1] > recent[0] ? .bullish : recent[1] < recent[0] ? .bearish : .neutral
    }
}

struct RSIData: Codable, Sendable {
    let period: Int
    let values: [TechnicalIndicatorValue]
    
    var current: Double? {
        values.last?.value
    }
    
    var signal: RSISignal {
        guard let current = current else { return .neutral }
        if current >= 70 { return .overbought }
        if current <= 30 { return .oversold }
        return .neutral
    }
}

struct MACDData: Codable, Sendable {
    let macdLine: [TechnicalIndicatorValue]
    let signalLine: [TechnicalIndicatorValue]
    let histogram: [TechnicalIndicatorValue]
    
    var currentMACD: Double? { macdLine.last?.value }
    var currentSignal: Double? { signalLine.last?.value }
    var currentHistogram: Double? { histogram.last?.value }
    
    var crossoverSignal: MACDSignal {
        guard let macd = currentMACD, let signal = currentSignal else { return .neutral }
        if macd > signal && (macdLine.dropLast().last?.value ?? 0) <= (signalLine.dropLast().last?.value ?? 0) {
            return .bullishCrossover
        }
        if macd < signal && (macdLine.dropLast().last?.value ?? 0) >= (signalLine.dropLast().last?.value ?? 0) {
            return .bearishCrossover
        }
        return .neutral
    }
}

struct BollingerBandsData: Codable, Sendable {
    let upperBand: [TechnicalIndicatorValue]
    let middleBand: [TechnicalIndicatorValue] // SMA
    let lowerBand: [TechnicalIndicatorValue]
    
    var currentUpper: Double? { upperBand.last?.value }
    var currentMiddle: Double? { middleBand.last?.value }
    var currentLower: Double? { lowerBand.last?.value }
    
    func getBandSignal(currentPrice: Double) -> BollingerSignal {
        guard let upper = currentUpper, let lower = currentLower else { return .neutral }
        if currentPrice >= upper { return .overbought }
        if currentPrice <= lower { return .oversold }
        return .neutral
    }
}

struct VolumeIndicators: Codable, Sendable {
    let volumeMA: MovingAverageData
    let onBalanceVolume: [TechnicalIndicatorValue]
    let volumeRSI: RSIData
    
    var volumeTrend: VolumeTrend {
        guard let currentVol = volumeMA.values.last?.value,
              let avgVol = volumeMA.current else { return .normal }
        
        if currentVol > avgVol * 1.5 { return .high }
        if currentVol < avgVol * 0.7 { return .low }
        return .normal
    }
}

// MARK: - Technical Analysis Summary

struct TechnicalAnalysis: Codable, Sendable {
    let currencyPairId: String
    let timestamp: Date
    let timeframe: ChartTimeframe
    
    // Moving Averages
    let sma20: MovingAverageData
    let sma50: MovingAverageData
    let sma200: MovingAverageData
    let ema12: MovingAverageData
    let ema26: MovingAverageData
    
    // Momentum Indicators
    let rsi: RSIData
    let macd: MACDData
    let stochastic: StochasticData
    
    // Volatility Indicators
    let bollingerBands: BollingerBandsData
    let atr: [TechnicalIndicatorValue] // Average True Range
    
    // Volume Indicators
    let volumeIndicators: VolumeIndicators
    
    // Support and Resistance
    let supportLevels: [SupportResistanceLevel]
    let resistanceLevels: [SupportResistanceLevel]
    
    var overallSignal: TechnicalSignal {
        let signals = [
            getMASignal(),
            rsi.signal.technicalSignal,
            macd.crossoverSignal.technicalSignal,
            stochastic.signal.technicalSignal
        ]
        
        let bullishCount = signals.filter { $0 == .bullish }.count
        let bearishCount = signals.filter { $0 == .bearish }.count
        
        if bullishCount > bearishCount { return .bullish }
        if bearishCount > bullishCount { return .bearish }
        return .neutral
    }
    
    var signalStrength: SignalStrength {
        let signals = [
            getMASignal(),
            rsi.signal.technicalSignal,
            macd.crossoverSignal.technicalSignal,
            stochastic.signal.technicalSignal
        ]
        
        let strongSignals = signals.filter { $0 != .neutral }.count
        let totalSignals = signals.count
        let strength = Double(strongSignals) / Double(totalSignals)
        
        if strength >= 0.75 { return .strong }
        if strength >= 0.5 { return .moderate }
        if strength >= 0.25 { return .weak }
        return .veryWeak
    }
}

struct StochasticData: Codable, Sendable {
    let kPercent: [TechnicalIndicatorValue]
    let dPercent: [TechnicalIndicatorValue]
    
    var currentK: Double? { kPercent.last?.value }
    var currentD: Double? { dPercent.last?.value }
    
    var signal: StochasticSignal {
        guard let k = currentK, let d = currentD else { return .neutral }
        
        if k >= 80 && d >= 80 { return .overbought }
        if k <= 20 && d <= 20 { return .oversold }
        
        // Bullish crossover: %K crosses above %D in oversold region
        if k > d && k <= 30 { return .bullishCrossover }
        
        // Bearish crossover: %K crosses below %D in overbought region
        if k < d && k >= 70 { return .bearishCrossover }
        
        return .neutral
    }
}

struct SupportResistanceLevel: Codable, Sendable, Identifiable {
    let id: UUID
    let price: Double
    let strength: Double // 0.0 to 1.0
    let touchCount: Int
    let type: SupportResistanceType
    let timeframe: ChartTimeframe
    
    init(price: Double, strength: Double, touchCount: Int, type: SupportResistanceType, timeframe: ChartTimeframe) {
        self.id = UUID()
        self.price = price
        self.strength = strength
        self.touchCount = touchCount
        self.type = type
        self.timeframe = timeframe
    }
    
    private enum CodingKeys: String, CodingKey {
        case price, strength, touchCount, type, timeframe
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.price = try container.decode(Double.self, forKey: .price)
        self.strength = try container.decode(Double.self, forKey: .strength)
        self.touchCount = try container.decode(Int.self, forKey: .touchCount)
        self.type = try container.decode(SupportResistanceType.self, forKey: .type)
        self.timeframe = try container.decode(ChartTimeframe.self, forKey: .timeframe)
    }
}

// MARK: - Market Analysis Summary

struct MarketAnalysis: Codable, Sendable {
    let currencyPairId: String
    let timestamp: Date
    
    let technicalAnalysis: TechnicalAnalysis
    let marketSentiment: MarketSentiment
    let priceTargets: [PriceTarget]
    let riskAssessment: RiskAssessment
    
    var recommendation: TradingRecommendation {
        let technicalWeight = 0.4
        let sentimentWeight = 0.3
        let riskWeight = 0.3
        
        let technicalScore = technicalAnalysis.overallSignal.numericValue
        let sentimentScore = marketSentiment.overallSentiment.numericValue
        let riskScore = 1.0 - riskAssessment.riskLevel.numericValue
        
        let weightedScore = (technicalScore * technicalWeight) + 
                           (sentimentScore * sentimentWeight) + 
                           (riskScore * riskWeight)
        
        if weightedScore >= 0.6 { return .strongBuy }
        if weightedScore >= 0.3 { return .buy }
        if weightedScore >= -0.3 { return .hold }
        if weightedScore >= -0.6 { return .sell }
        return .strongSell
    }
}

struct MarketSentiment: Codable, Sendable {
    let fearGreedIndex: Double // 0-100
    let socialSentiment: Double // -1 to 1
    let newsImpact: Double // -1 to 1
    let institutionalFlow: Double // -1 to 1
    
    var overallSentiment: SentimentDirection {
        let average = (socialSentiment + newsImpact + institutionalFlow) / 3.0
        if average >= 0.3 { return .bullish }
        if average <= -0.3 { return .bearish }
        return .neutral
    }
}

struct PriceTarget: Codable, Sendable, Identifiable {
    let id: UUID
    let price: Double
    let probability: Double // 0.0 to 1.0
    let timeframe: TargetTimeframe
    let type: TargetType
    let rationale: String
    
    init(price: Double, probability: Double, timeframe: TargetTimeframe, type: TargetType, rationale: String) {
        self.id = UUID()
        self.price = price
        self.probability = probability
        self.timeframe = timeframe
        self.type = type
        self.rationale = rationale
    }
    
    private enum CodingKeys: String, CodingKey {
        case price, probability, timeframe, type, rationale
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.price = try container.decode(Double.self, forKey: .price)
        self.probability = try container.decode(Double.self, forKey: .probability)
        self.timeframe = try container.decode(TargetTimeframe.self, forKey: .timeframe)
        self.type = try container.decode(TargetType.self, forKey: .type)
        self.rationale = try container.decode(String.self, forKey: .rationale)
    }
}

struct RiskAssessment: Codable, Sendable {
    let volatility: Double // 0.0 to 1.0
    let liquidityRisk: Double // 0.0 to 1.0
    let correlationRisk: Double // 0.0 to 1.0
    let maxDrawdown: Double // Historical max drawdown percentage
    
    var riskLevel: RiskLevel {
        let averageRisk = (volatility + liquidityRisk + correlationRisk) / 3.0
        if averageRisk >= 0.7 { return .high }
        if averageRisk >= 0.4 { return .medium }
        return .low
    }
    
    var riskScore: Double {
        (volatility + liquidityRisk + correlationRisk) / 3.0
    }
}

// MARK: - Enums

enum TechnicalSignal: String, Codable, Sendable, CaseIterable {
    case bullish = "bullish"
    case bearish = "bearish"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .bullish: return "Bullish"
        case .bearish: return "Bearish"
        case .neutral: return "Neutral"
        }
    }
    
    var color: String {
        switch self {
        case .bullish: return "green"
        case .bearish: return "red"
        case .neutral: return "gray"
        }
    }
    
    var numericValue: Double {
        switch self {
        case .bullish: return 1.0
        case .neutral: return 0.0
        case .bearish: return -1.0
        }
    }
}

enum TrendDirection: String, Codable, Sendable {
    case bullish = "bullish"
    case bearish = "bearish"
    case neutral = "neutral"
}

enum RSISignal: String, Codable, Sendable {
    case overbought = "overbought"
    case oversold = "oversold"
    case neutral = "neutral"
    
    var technicalSignal: TechnicalSignal {
        switch self {
        case .overbought: return .bearish
        case .oversold: return .bullish
        case .neutral: return .neutral
        }
    }
}

enum MACDSignal: String, Codable, Sendable {
    case bullishCrossover = "bullish_crossover"
    case bearishCrossover = "bearish_crossover"
    case neutral = "neutral"
    
    var technicalSignal: TechnicalSignal {
        switch self {
        case .bullishCrossover: return .bullish
        case .bearishCrossover: return .bearish
        case .neutral: return .neutral
        }
    }
}

enum BollingerSignal: String, Codable, Sendable {
    case overbought = "overbought"
    case oversold = "oversold"
    case neutral = "neutral"
}

enum StochasticSignal: String, Codable, Sendable {
    case overbought = "overbought"
    case oversold = "oversold"
    case bullishCrossover = "bullish_crossover"
    case bearishCrossover = "bearish_crossover"
    case neutral = "neutral"
    
    var technicalSignal: TechnicalSignal {
        switch self {
        case .overbought, .bearishCrossover: return .bearish
        case .oversold, .bullishCrossover: return .bullish
        case .neutral: return .neutral
        }
    }
}

enum VolumeTrend: String, Codable, Sendable {
    case high = "high"
    case normal = "normal"
    case low = "low"
}

enum SignalStrength: String, Codable, Sendable {
    case strong = "strong"
    case moderate = "moderate"
    case weak = "weak"
    case veryWeak = "very_weak"
    
    var displayName: String {
        switch self {
        case .strong: return "Strong"
        case .moderate: return "Moderate"
        case .weak: return "Weak"
        case .veryWeak: return "Very Weak"
        }
    }
}

enum SupportResistanceType: String, Codable, Sendable {
    case support = "support"
    case resistance = "resistance"
}

enum ChartTimeframe: String, Codable, Sendable, CaseIterable {
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case thirtyMinutes = "30m"
    case oneHour = "1h"
    case fourHours = "4h"
    case oneDay = "1d"
    case oneWeek = "1w"
    case oneMonth = "1M"
    
    var displayName: String {
        switch self {
        case .oneMinute: return "1 Minute"
        case .fiveMinutes: return "5 Minutes"
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .oneHour: return "1 Hour"
        case .fourHours: return "4 Hours"
        case .oneDay: return "1 Day"
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        }
    }
}

enum TradingRecommendation: String, Codable, Sendable {
    case strongBuy = "strong_buy"
    case buy = "buy"
    case hold = "hold"
    case sell = "sell"
    case strongSell = "strong_sell"
    
    var displayName: String {
        switch self {
        case .strongBuy: return "Strong Buy"
        case .buy: return "Buy"
        case .hold: return "Hold"
        case .sell: return "Sell"
        case .strongSell: return "Strong Sell"
        }
    }
    
    var color: String {
        switch self {
        case .strongBuy, .buy: return "green"
        case .hold: return "orange"
        case .sell, .strongSell: return "red"
        }
    }
}

enum SentimentDirection: String, Codable, Sendable {
    case bullish = "bullish"
    case bearish = "bearish"
    case neutral = "neutral"
    
    var numericValue: Double {
        switch self {
        case .bullish: return 1.0
        case .neutral: return 0.0
        case .bearish: return -1.0
        }
    }
}

enum TargetTimeframe: String, Codable, Sendable {
    case shortTerm = "short_term" // 1-7 days
    case mediumTerm = "medium_term" // 1-4 weeks
    case longTerm = "long_term" // 1-6 months
    
    var displayName: String {
        switch self {
        case .shortTerm: return "Short Term (1-7 days)"
        case .mediumTerm: return "Medium Term (1-4 weeks)"
        case .longTerm: return "Long Term (1-6 months)"
        }
    }
}

enum TargetType: String, Codable, Sendable {
    case resistance = "resistance"
    case support = "support"
    case fibonacci = "fibonacci"
    case technical = "technical"
}

enum RiskLevel: String, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
    
    var numericValue: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 1.0
        }
    }
}