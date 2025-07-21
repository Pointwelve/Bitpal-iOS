//
//  Alert.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class Alert: Codable {
    @Attribute(.unique) var id: String
    var targetPrice: Double
    var comparison: AlertComparison
    var isEnabled: Bool
    var createdAt: Date
    var lastTriggered: Date?
    var lastModified: Date
    var isDeleted: Bool
    var note: String?
    var message: String?
    
    @Relationship(deleteRule: .nullify) var currencyPair: CurrencyPair?
    
    init(
        currencyPair: CurrencyPair,
        comparison: AlertComparison,
        targetPrice: Double,
        isEnabled: Bool = true,
        note: String? = nil
    ) {
        self.id = UUID().uuidString
        self.currencyPair = currencyPair
        self.comparison = comparison
        self.targetPrice = targetPrice
        self.isEnabled = isEnabled
        self.note = note
        self.createdAt = Date()
        self.lastModified = Date()
        self.isDeleted = false
    }
    
    var displayTitle: String {
        guard let pair = currencyPair else { return "Unknown Alert" }
        return "\(pair.displayName) \(comparison.symbol) \(formatPrice(targetPrice))"
    }
    
    var shouldTrigger: Bool {
        guard isEnabled, let pair = currencyPair else { return false }
        
        switch comparison {
        case .above:
            return pair.currentPrice >= targetPrice
        case .below:
            return pair.currentPrice <= targetPrice
        }
    }
    
    var canTrigger: Bool {
        guard let lastTriggered = lastTriggered else { return true }
        // Prevent duplicate alerts within 1 hour
        return Date().timeIntervalSince(lastTriggered) > 3600
    }
    
    func trigger() {
        lastTriggered = Date()
        lastModified = Date()
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "$%.0f", price)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.targetPrice = try container.decode(Double.self, forKey: .targetPrice)
        self.comparison = try container.decode(AlertComparison.self, forKey: .comparison)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.lastTriggered = try container.decodeIfPresent(Date.self, forKey: .lastTriggered)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.currencyPair = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(targetPrice, forKey: .targetPrice)
        try container.encode(comparison, forKey: .comparison)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastTriggered, forKey: .lastTriggered)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(message, forKey: .message)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, targetPrice, comparison, isEnabled, createdAt, lastTriggered
        case lastModified, isDeleted, note, message
    }
    
}

enum AlertComparison: String, CaseIterable, Codable, Sendable {
    case above = "above"
    case below = "below"
    
    var symbol: String {
        switch self {
        case .above: return "≥"
        case .below: return "≤"
        }
    }
    
    var displayName: String {
        switch self {
        case .above: return "Above"
        case .below: return "Below"
        }
    }
}

@Model
final class AlertList {
    @Attribute(.unique) var id: String
    var lastModified: Date
    var isDeleted: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var alerts: [Alert] = []
    
    init(id: String = "default") {
        self.id = id
        self.lastModified = Date()
        self.isDeleted = false
        self.createdAt = Date()
    }
    
    var enabledAlerts: [Alert] {
        alerts.filter { $0.isEnabled }
    }
    
    var triggeredAlerts: [Alert] {
        alerts.filter { $0.shouldTrigger && $0.canTrigger }
    }
    
    func addAlert(_ alert: Alert) {
        alerts.append(alert)
        lastModified = Date()
    }
    
    func removeAlert(_ alert: Alert) {
        alerts.removeAll { $0.id == alert.id }
        lastModified = Date()
    }
    
}