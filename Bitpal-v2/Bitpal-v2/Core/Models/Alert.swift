//
//  Alert.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class Alert {
    @Attribute(.unique) var id: String
    var targetPrice: Double
    var comparison: AlertComparison
    var alertType: AlertType
    var priority: AlertPriority
    var isEnabled: Bool
    var isRepeatable: Bool
    var triggerCount: Int
    var maxTriggers: Int?
    var cooldownInterval: TimeInterval
    var createdAt: Date
    var lastTriggered: Date?
    var lastModified: Date
    var isDeleted: Bool
    var note: String?
    var customMessage: String?
    var soundEnabled: Bool
    var vibrationEnabled: Bool
    
    @Relationship(deleteRule: .nullify) var currencyPair: CurrencyPair?
    
    init(
        currencyPair: CurrencyPair,
        comparison: AlertComparison,
        targetPrice: Double,
        alertType: AlertType = .priceTarget,
        priority: AlertPriority = .medium,
        isEnabled: Bool = true,
        isRepeatable: Bool = false,
        maxTriggers: Int? = nil,
        cooldownInterval: TimeInterval = 3600, // 1 hour default
        note: String? = nil,
        customMessage: String? = nil,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true
    ) {
        self.id = UUID().uuidString
        self.currencyPair = currencyPair
        self.comparison = comparison
        self.targetPrice = max(0, targetPrice) // Ensure positive price
        self.alertType = alertType
        self.priority = priority
        self.isEnabled = isEnabled
        self.isRepeatable = isRepeatable
        self.triggerCount = 0
        self.maxTriggers = maxTriggers
        self.cooldownInterval = cooldownInterval
        self.note = note
        self.customMessage = customMessage
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        let now = Date()
        self.createdAt = now
        self.lastModified = now
        self.isDeleted = false
    }
    
    func markAsDeleted() {
        isDeleted = true
        lastModified = Date()
    }
    
    func restore() {
        isDeleted = false
        lastModified = Date()
    }
    
    func enable() {
        isEnabled = true
        lastModified = Date()
    }
    
    func disable() {
        isEnabled = false
        lastModified = Date()
    }
    
    func updateLastModified() {
        lastModified = Date()
    }
}

// MARK: - Alert Logic
extension Alert {
    var shouldTrigger: Bool {
        guard isEnabled && !isDeleted, let pair = currencyPair else { return false }
        
        // Check if max triggers reached
        if let maxTriggers = maxTriggers, triggerCount >= maxTriggers {
            return false
        }
        
        // Check cooldown period
        if !canTrigger {
            return false
        }
        
        // Check price condition
        return checkPriceCondition(currentPrice: pair.currentPrice)
    }
    
    var canTrigger: Bool {
        guard let lastTriggered = lastTriggered else { return true }
        return Date().timeIntervalSince(lastTriggered) >= cooldownInterval
    }
    
    private func checkPriceCondition(currentPrice: Double) -> Bool {
        switch comparison {
        case .above:
            return currentPrice >= targetPrice
        case .below:
            return currentPrice <= targetPrice
        case .exactMatch:
            let tolerance = targetPrice * 0.001 // 0.1% tolerance
            return abs(currentPrice - targetPrice) <= tolerance
        case .percentageChange:
            guard let pair = currencyPair else { return false }
            return abs(pair.priceChangePercent24h) >= targetPrice
        }
    }
    
    func trigger() -> Bool {
        guard shouldTrigger else { return false }
        
        triggerCount += 1
        lastTriggered = Date()
        lastModified = Date()
        
        // Auto-disable if not repeatable and triggered once
        if !isRepeatable {
            isEnabled = false
        }
        
        // Auto-disable if max triggers reached
        if let maxTriggers = maxTriggers, triggerCount >= maxTriggers {
            isEnabled = false
        }
        
        return true
    }
    
    func reset() {
        triggerCount = 0
        lastTriggered = nil
        isEnabled = true
        lastModified = Date()
    }
}

// MARK: - Computed Properties
extension Alert {
    var displayTitle: String {
        guard let pair = currencyPair else { return "Unknown Alert" }
        
        switch alertType {
        case .priceTarget:
            return "\(pair.displayName) \(comparison.symbol) \(formatPrice(targetPrice))"
        case .percentageChange:
            return "\(pair.displayName) change ≥ \(targetPrice.formatted(.percent.precision(.fractionLength(1))))"
        case .volumeSpike:
            return "\(pair.displayName) volume spike"
        case .technicalIndicator:
            return "\(pair.displayName) technical signal"
        }
    }
    
    var displayMessage: String {
        if let customMessage = customMessage, !customMessage.isEmpty {
            return customMessage
        }
        
        guard let pair = currencyPair else { return "Alert triggered" }
        
        switch alertType {
        case .priceTarget:
            return "\(pair.displayName) has reached \(formatPrice(targetPrice))"
        case .percentageChange:
            return "\(pair.displayName) has changed by \(targetPrice.formatted(.percent))"
        case .volumeSpike:
            return "\(pair.displayName) is experiencing high volume"
        case .technicalIndicator:
            return "\(pair.displayName) technical indicator triggered"
        }
    }
    
    var isActive: Bool {
        isEnabled && !isDeleted
    }
    
    var isExpired: Bool {
        guard let maxTriggers = maxTriggers else { return false }
        return triggerCount >= maxTriggers
    }
    
    var timeUntilCanTrigger: TimeInterval {
        guard let lastTriggered = lastTriggered else { return 0 }
        let timeSinceLastTrigger = Date().timeIntervalSince(lastTriggered)
        return max(0, cooldownInterval - timeSinceLastTrigger)
    }
    
    var progressToTarget: Double? {
        guard let pair = currencyPair, alertType == .priceTarget else { return nil }
        
        switch comparison {
        case .above:
            guard targetPrice > pair.open24h else { return nil }
            let progress = (pair.currentPrice - pair.open24h) / (targetPrice - pair.open24h)
            return max(0, min(1, progress))
        case .below:
            guard targetPrice < pair.open24h else { return nil }
            let progress = (pair.open24h - pair.currentPrice) / (pair.open24h - targetPrice)
            return max(0, min(1, progress))
        default:
            return nil
        }
    }
}

// MARK: - Formatting
extension Alert {
    private func formatPrice(_ price: Double) -> String {
        guard let pair = currencyPair else {
            return price.formatted(.currency(code: "USD"))
        }
        
        let currencyCode = pair.quoteCurrency?.symbol ?? "USD"
        
        if price >= 1000 {
            return price.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
        } else if price >= 1 {
            return price.formatted(.currency(code: currencyCode).precision(.fractionLength(2)))
        } else if price >= 0.01 {
            return price.formatted(.currency(code: currencyCode).precision(.fractionLength(4)))
        } else {
            return price.formatted(.currency(code: currencyCode).precision(.fractionLength(6)))
        }
    }
}

// MARK: - Validation
extension Alert {
    var isValidAlert: Bool {
        guard !id.isEmpty,
              targetPrice > 0,
              let pair = currencyPair,
              pair.isValidPair else {
            return false
        }
        
        switch alertType {
        case .priceTarget:
            return targetPrice > 0
        case .percentageChange:
            return targetPrice >= 0 && targetPrice <= 100
        case .volumeSpike, .technicalIndicator:
            return true
        }
    }
    
    var hasReasonableTarget: Bool {
        guard let pair = currencyPair else { return false }
        
        switch comparison {
        case .above:
            return targetPrice > pair.currentPrice * 0.9 // At least 10% below current
        case .below:
            return targetPrice < pair.currentPrice * 1.1 // At least 10% above current
        default:
            return true
        }
    }
}

// MARK: - Supporting Enums
enum AlertComparison: String, CaseIterable, Codable, Sendable {
    case above = "above"
    case below = "below"
    case exactMatch = "exact"
    case percentageChange = "percentage"
    
    var symbol: String {
        switch self {
        case .above: return "≥"
        case .below: return "≤"
        case .exactMatch: return "="
        case .percentageChange: return "Δ%"
        }
    }
    
    var displayName: String {
        switch self {
        case .above: return "Above"
        case .below: return "Below"
        case .exactMatch: return "Exactly"
        case .percentageChange: return "% Change"
        }
    }
}

enum AlertType: String, CaseIterable, Codable, Sendable {
    case priceTarget = "price"
    case percentageChange = "percentage"
    case volumeSpike = "volume"
    case technicalIndicator = "technical"
    
    var displayName: String {
        switch self {
        case .priceTarget: return "Price Target"
        case .percentageChange: return "Price Change"
        case .volumeSpike: return "Volume Spike"
        case .technicalIndicator: return "Technical Signal"
        }
    }
    
    var icon: String {
        switch self {
        case .priceTarget: return "target"
        case .percentageChange: return "percent"
        case .volumeSpike: return "chart.bar.fill"
        case .technicalIndicator: return "waveform.path.ecg"
        }
    }
}

enum AlertPriority: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Codable
extension Alert: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, targetPrice, comparison, alertType, priority
        case isEnabled, isRepeatable, triggerCount, maxTriggers, cooldownInterval
        case createdAt, lastTriggered, lastModified, isDeleted
        case note, customMessage, soundEnabled, vibrationEnabled
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let targetPrice = try container.decode(Double.self, forKey: .targetPrice)
        let comparison = try container.decode(AlertComparison.self, forKey: .comparison)
        let alertType = try container.decodeIfPresent(AlertType.self, forKey: .alertType) ?? .priceTarget
        let priority = try container.decodeIfPresent(AlertPriority.self, forKey: .priority) ?? .medium
        let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        let isRepeatable = try container.decodeIfPresent(Bool.self, forKey: .isRepeatable) ?? false
        let maxTriggers = try container.decodeIfPresent(Int.self, forKey: .maxTriggers)
        let cooldownInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .cooldownInterval) ?? 3600
        let note = try container.decodeIfPresent(String.self, forKey: .note)
        let customMessage = try container.decodeIfPresent(String.self, forKey: .customMessage)
        let soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        let vibrationEnabled = try container.decodeIfPresent(Bool.self, forKey: .vibrationEnabled) ?? true
        
        self.init(
            currencyPair: Exchange.coinbase().createPair(baseCurrency: Currency.bitcoin(), quoteCurrency: Currency.usd()), // Temporary
            comparison: comparison,
            targetPrice: targetPrice,
            alertType: alertType,
            priority: priority,
            isEnabled: isEnabled,
            isRepeatable: isRepeatable,
            maxTriggers: maxTriggers,
            cooldownInterval: cooldownInterval,
            note: note,
            customMessage: customMessage,
            soundEnabled: soundEnabled,
            vibrationEnabled: vibrationEnabled
        )
        
        // Override with decoded values
        self.id = id
        self.triggerCount = try container.decodeIfPresent(Int.self, forKey: .triggerCount) ?? 0
        self.lastTriggered = try container.decodeIfPresent(Date.self, forKey: .lastTriggered)
        
        if let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) {
            self.createdAt = createdAt
        }
        if let lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) {
            self.lastModified = lastModified
        }
        if let isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) {
            self.isDeleted = isDeleted
        }
        
        // Clear relationships - they'll be set by the persistence layer
        self.currencyPair = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(targetPrice, forKey: .targetPrice)
        try container.encode(comparison, forKey: .comparison)
        try container.encode(alertType, forKey: .alertType)
        try container.encode(priority, forKey: .priority)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(isRepeatable, forKey: .isRepeatable)
        try container.encode(triggerCount, forKey: .triggerCount)
        try container.encodeIfPresent(maxTriggers, forKey: .maxTriggers)
        try container.encode(cooldownInterval, forKey: .cooldownInterval)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastTriggered, forKey: .lastTriggered)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(customMessage, forKey: .customMessage)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(vibrationEnabled, forKey: .vibrationEnabled)
    }
}

// MARK: - Hashable & Equatable
extension Alert: Hashable {
    static func == (lhs: Alert, rhs: Alert) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - AlertList Model
@Model
final class AlertList {
    @Attribute(.unique) var id: String
    var name: String
    var lastModified: Date
    var isDeleted: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var alerts: [Alert] = []
    
    init(id: String = "default", name: String = "Default Alerts") {
        self.id = id
        self.name = name
        let now = Date()
        self.lastModified = now
        self.isDeleted = false
        self.createdAt = now
    }
    
    func markAsDeleted() {
        isDeleted = true
        lastModified = Date()
    }
    
    func restore() {
        isDeleted = false
        lastModified = Date()
    }
    
    func updateLastModified() {
        lastModified = Date()
    }
}

// MARK: - AlertList Computed Properties
extension AlertList {
    var activeAlerts: [Alert] {
        alerts.filter { $0.isActive }
    }
    
    var enabledAlerts: [Alert] {
        alerts.filter { $0.isEnabled && !$0.isDeleted }
    }
    
    var triggeredAlerts: [Alert] {
        alerts.filter { $0.shouldTrigger && $0.canTrigger }
    }
    
    var criticalAlerts: [Alert] {
        alerts.filter { $0.priority == .critical && $0.isActive }
    }
    
    var alertsByPriority: [Alert] {
        alerts.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
    }
    
    var alertCount: Int {
        alerts.count
    }
    
    var activeAlertCount: Int {
        activeAlerts.count
    }
}

// MARK: - AlertList Business Logic
extension AlertList {
    func addAlert(_ alert: Alert) {
        alerts.append(alert)
        lastModified = Date()
    }
    
    func removeAlert(_ alert: Alert) {
        alerts.removeAll { $0.id == alert.id }
        lastModified = Date()
    }
    
    func removeAlert(withId id: String) {
        alerts.removeAll { $0.id == id }
        lastModified = Date()
    }
    
    func enableAllAlerts() {
        alerts.forEach { $0.enable() }
        lastModified = Date()
    }
    
    func disableAllAlerts() {
        alerts.forEach { $0.disable() }
        lastModified = Date()
    }
    
    func clearTriggeredAlerts() {
        alerts.forEach { alert in
            if alert.triggerCount > 0 {
                alert.reset()
            }
        }
        lastModified = Date()
    }
    
    func findAlert(withId id: String) -> Alert? {
        alerts.first { $0.id == id }
    }
    
    func hasAlert(for currencyPair: CurrencyPair, comparison: AlertComparison, targetPrice: Double) -> Bool {
        alerts.contains { alert in
            alert.currencyPair?.id == currencyPair.id &&
            alert.comparison == comparison &&
            abs(alert.targetPrice - targetPrice) < 0.01
        }
    }
}