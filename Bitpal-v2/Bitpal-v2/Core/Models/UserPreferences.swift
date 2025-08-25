//
//  UserPreferences.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class UserPreferences: Codable {
    @Attribute(.unique) var id: String
    var currency: String
    var theme: String
    var notificationsEnabled: Bool
    var newsAlertsEnabled: Bool
    var biometricAuthEnabled: Bool
    var defaultChartPeriod: String
    var refreshIntervalSeconds: Double
    var createdAt: Date
    var lastModified: Date
    
    init(
        currency: String = "USD",
        theme: String = "system",
        notificationsEnabled: Bool = true,
        newsAlertsEnabled: Bool = false,
        biometricAuthEnabled: Bool = false,
        defaultChartPeriod: String = "1d",
        refreshIntervalSeconds: Double = 60.0
    ) {
        self.id = UUID().uuidString
        self.currency = currency
        self.theme = theme
        self.notificationsEnabled = notificationsEnabled
        self.newsAlertsEnabled = newsAlertsEnabled
        self.biometricAuthEnabled = biometricAuthEnabled
        self.defaultChartPeriod = defaultChartPeriod
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.currency = try container.decode(String.self, forKey: .currency)
        self.theme = try container.decode(String.self, forKey: .theme)
        self.notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        self.newsAlertsEnabled = try container.decode(Bool.self, forKey: .newsAlertsEnabled)
        self.biometricAuthEnabled = try container.decode(Bool.self, forKey: .biometricAuthEnabled)
        self.defaultChartPeriod = try container.decode(String.self, forKey: .defaultChartPeriod)
        self.refreshIntervalSeconds = try container.decode(Double.self, forKey: .refreshIntervalSeconds)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(currency, forKey: .currency)
        try container.encode(theme, forKey: .theme)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(newsAlertsEnabled, forKey: .newsAlertsEnabled)
        try container.encode(biometricAuthEnabled, forKey: .biometricAuthEnabled)
        try container.encode(defaultChartPeriod, forKey: .defaultChartPeriod)
        try container.encode(refreshIntervalSeconds, forKey: .refreshIntervalSeconds)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastModified, forKey: .lastModified)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, currency, theme, notificationsEnabled
        case newsAlertsEnabled, biometricAuthEnabled, defaultChartPeriod
        case refreshIntervalSeconds, createdAt, lastModified
    }
}

enum Theme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}