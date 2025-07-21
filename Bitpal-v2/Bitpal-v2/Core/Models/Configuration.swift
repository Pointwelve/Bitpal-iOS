//
//  Configuration.swift
//  Bitpal-v2
//
//  Created by Ryne Cheow on 20/7/25.
//

import Foundation
import SwiftData

@Model
final class Configuration {
    @Attribute(.unique) var id: String
    var apiHost: String
    var functionsHost: String
    var socketHost: String
    var sslCertificateData: Data?
    var companyName: String
    var apiKey: String
    var termsAndConditions: String
    var privacyPolicy: String
    var supportEmail: String
    var version: String
    var lastModified: Date
    var createdAt: Date
    
    init(
        id: String = "default",
        apiHost: String = "https://data-api.coindesk.com",
        functionsHost: String = "https://data-api.coindesk.com",
        socketHost: String = "wss://data-streamer.coindesk.com",
        companyName: String = "Bitpal",
        apiKey: String = "a10b6019948f0cd3183025f3f306083209665c4267fcd01db73a4a58e6123c2d",
        termsAndConditions: String = "https://bitpal.app/terms",
        privacyPolicy: String = "https://bitpal.app/privacy",
        supportEmail: String = "support@bitpal.app",
        version: String = "2.0.0"
    ) {
        self.id = id
        self.apiHost = apiHost
        self.functionsHost = functionsHost
        self.socketHost = socketHost
        self.companyName = companyName
        self.apiKey = apiKey
        self.termsAndConditions = termsAndConditions
        self.privacyPolicy = privacyPolicy
        self.supportEmail = supportEmail
        self.version = version
        self.lastModified = Date()
        self.createdAt = Date()
    }
    
    var isValid: Bool {
        !apiKey.isEmpty && !apiHost.isEmpty && !socketHost.isEmpty
    }
    
    func update(
        apiHost: String? = nil,
        functionsHost: String? = nil,
        socketHost: String? = nil,
        apiKey: String? = nil
    ) {
        if let apiHost = apiHost { self.apiHost = apiHost }
        if let functionsHost = functionsHost { self.functionsHost = functionsHost }
        if let socketHost = socketHost { self.socketHost = socketHost }
        if let apiKey = apiKey { self.apiKey = apiKey }
        self.lastModified = Date()
    }
}


enum Language: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "中文"
        }
    }
    
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}


enum ChartType: String, CaseIterable, Codable, Sendable {
    case line = "line"
    case candlestick = "candlestick"
    case area = "area"
    
    var displayName: String {
        switch self {
        case .line: return "Line"
        case .candlestick: return "Candlestick"
        case .area: return "Area"
        }
    }
    
    var systemImage: String {
        switch self {
        case .line: return "chart.line.uptrend.xyaxis"
        case .candlestick: return "chart.bar.fill"
        case .area: return "chart.line.flattrend.xyaxis.fill"
        }
    }
}