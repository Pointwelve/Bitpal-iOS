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
    var backupHosts: [String]
    var sslCertificateData: Data?
    var companyName: String
    var apiKey: String
    var termsAndConditions: String
    var privacyPolicy: String
    var supportEmail: String
    var appStoreURL: String?
    var websiteURL: String?
    var version: String
    var buildNumber: String
    var minSupportedVersion: String
    var environment: AppEnvironment
    var theme: AppTheme
    var preferredLanguage: Language
    var preferredCurrency: String
    var preferredChartType: ChartType
    var refreshInterval: TimeInterval
    var requestTimeout: TimeInterval
    var maxRetries: Int
    var enableAnalytics: Bool
    var enableCrashReporting: Bool
    var enableDebugMode: Bool
    var enablePushNotifications: Bool
    var enableBackgroundRefresh: Bool
    var cacheEnabled: Bool
    var cacheTTL: TimeInterval
    var maxCacheSize: Int
    var isDeleted: Bool
    var lastModified: Date
    var createdAt: Date
    
    init(
        id: String = "default",
        apiHost: String = "https://data-api.coindesk.com",
        functionsHost: String = "https://data-api.coindesk.com",
        socketHost: String = "wss://data-streamer.coindesk.com",
        backupHosts: [String] = ["https://backup-api.coindesk.com"],
        companyName: String = "Bitpal",
        apiKey: String = "a10b6019948f0cd3183025f3f306083209665c4267fcd01db73a4a58e6123c2d",
        termsAndConditions: String = "https://bitpal.app/terms",
        privacyPolicy: String = "https://bitpal.app/privacy",
        supportEmail: String = "support@bitpal.app",
        appStoreURL: String? = "https://apps.apple.com/app/bitpal",
        websiteURL: String? = "https://bitpal.app",
        version: String = "2.0.0",
        buildNumber: String = "1",
        environment: AppEnvironment = .production
    ) {
        self.id = id
        self.apiHost = apiHost
        self.functionsHost = functionsHost
        self.socketHost = socketHost
        self.backupHosts = backupHosts
        self.companyName = companyName
        self.apiKey = apiKey
        self.termsAndConditions = termsAndConditions
        self.privacyPolicy = privacyPolicy
        self.supportEmail = supportEmail
        self.appStoreURL = appStoreURL
        self.websiteURL = websiteURL
        self.version = version
        self.buildNumber = buildNumber
        self.minSupportedVersion = "1.0.0"
        self.environment = environment
        self.theme = .automatic
        self.preferredLanguage = .english
        self.preferredCurrency = "USD"
        self.preferredChartType = .line
        self.refreshInterval = 30.0
        self.requestTimeout = 10.0
        self.maxRetries = 3
        self.enableAnalytics = true
        self.enableCrashReporting = true
        self.enableDebugMode = false
        self.enablePushNotifications = true
        self.enableBackgroundRefresh = true
        self.cacheEnabled = true
        self.cacheTTL = 300.0 // 5 minutes
        self.maxCacheSize = 100 // MB
        let now = Date()
        self.lastModified = now
        self.createdAt = now
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
    
    func updateLastModified() {
        lastModified = Date()
    }
}

// MARK: - Factory Methods
extension Configuration {
    static func development() -> Configuration {
        Configuration(
            id: "dev",
            apiHost: "https://dev-api.coindesk.com",
            functionsHost: "https://dev-api.coindesk.com",
            socketHost: "wss://dev-streamer.coindesk.com",
            backupHosts: ["https://dev-backup.coindesk.com"],
            environment: .development
        )
    }
    
    static func staging() -> Configuration {
        Configuration(
            id: "staging",
            apiHost: "https://staging-api.coindesk.com",
            functionsHost: "https://staging-api.coindesk.com",
            socketHost: "wss://staging-streamer.coindesk.com",
            backupHosts: ["https://staging-backup.coindesk.com"],
            environment: .staging
        )
    }
    
    static func production() -> Configuration {
        Configuration(
            id: "production",
            apiHost: "https://data-api.coindesk.com",
            functionsHost: "https://data-api.coindesk.com",
            socketHost: "wss://data-streamer.coindesk.com",
            backupHosts: ["https://backup-api.coindesk.com", "https://backup2-api.coindesk.com"],
            environment: .production
        )
    }
    
    static func defaultConfiguration() -> Configuration {
        Configuration()
    }
}

// MARK: - Computed Properties
extension Configuration {
    var isValid: Bool {
        !apiKey.isEmpty && 
        !apiHost.isEmpty && 
        !socketHost.isEmpty &&
        !companyName.isEmpty &&
        !version.isEmpty &&
        !buildNumber.isEmpty
    }
    
    var isActive: Bool {
        !isDeleted && isValid
    }
    
    var displayName: String {
        "\(companyName) \(version) (\(buildNumber))"
    }
    
    var fullVersion: String {
        "\(version).\(buildNumber)"
    }
    
    var isDevelopment: Bool {
        environment == .development
    }
    
    var isProduction: Bool {
        environment == .production
    }
    
    var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return enableDebugMode
        #endif
    }
    
    var hasValidSSLCertificate: Bool {
        sslCertificateData != nil && !(sslCertificateData?.isEmpty ?? true)
    }
    
    var hasBackupHosts: Bool {
        !backupHosts.isEmpty
    }
    
    var effectiveRefreshInterval: TimeInterval {
        max(5.0, min(refreshInterval, 300.0)) // Between 5 seconds and 5 minutes
    }
    
    var effectiveRequestTimeout: TimeInterval {
        max(5.0, min(requestTimeout, 60.0)) // Between 5 seconds and 1 minute
    }
    
    var effectiveMaxRetries: Int {
        max(1, min(maxRetries, 10)) // Between 1 and 10 retries
    }
    
    var cacheSizeBytes: Int {
        maxCacheSize * 1024 * 1024 // Convert MB to bytes
    }
    
    var isRecentlyModified: Bool {
        Date().timeIntervalSince(lastModified) < 86400 // 24 hours
    }
    
    var configurationAge: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }
}

// MARK: - Business Logic
extension Configuration {
    func update(
        apiHost: String? = nil,
        functionsHost: String? = nil,
        socketHost: String? = nil,
        apiKey: String? = nil,
        environment: AppEnvironment? = nil,
        theme: AppTheme? = nil,
        language: Language? = nil,
        currency: String? = nil,
        chartType: ChartType? = nil
    ) {
        if let apiHost = apiHost { self.apiHost = apiHost }
        if let functionsHost = functionsHost { self.functionsHost = functionsHost }
        if let socketHost = socketHost { self.socketHost = socketHost }
        if let apiKey = apiKey { self.apiKey = apiKey }
        if let environment = environment { self.environment = environment }
        if let theme = theme { self.theme = theme }
        if let language = language { self.preferredLanguage = language }
        if let currency = currency { self.preferredCurrency = currency }
        if let chartType = chartType { self.preferredChartType = chartType }
        self.lastModified = Date()
    }
    
    func updateNetworkSettings(
        refreshInterval: TimeInterval? = nil,
        requestTimeout: TimeInterval? = nil,
        maxRetries: Int? = nil
    ) {
        if let refreshInterval = refreshInterval { 
            self.refreshInterval = max(5.0, min(refreshInterval, 300.0))
        }
        if let requestTimeout = requestTimeout { 
            self.requestTimeout = max(5.0, min(requestTimeout, 60.0))
        }
        if let maxRetries = maxRetries { 
            self.maxRetries = max(1, min(maxRetries, 10))
        }
        self.lastModified = Date()
    }
    
    func updateCacheSettings(
        enabled: Bool? = nil,
        ttl: TimeInterval? = nil,
        maxSize: Int? = nil
    ) {
        if let enabled = enabled { self.cacheEnabled = enabled }
        if let ttl = ttl { self.cacheTTL = max(60.0, ttl) } // Minimum 1 minute
        if let maxSize = maxSize { self.maxCacheSize = max(10, min(maxSize, 1000)) } // 10MB to 1GB
        self.lastModified = Date()
    }
    
    func updateFeatureFlags(
        analytics: Bool? = nil,
        crashReporting: Bool? = nil,
        debugMode: Bool? = nil,
        pushNotifications: Bool? = nil,
        backgroundRefresh: Bool? = nil
    ) {
        if let analytics = analytics { self.enableAnalytics = analytics }
        if let crashReporting = crashReporting { self.enableCrashReporting = crashReporting }
        if let debugMode = debugMode { self.enableDebugMode = debugMode }
        if let pushNotifications = pushNotifications { self.enablePushNotifications = pushNotifications }
        if let backgroundRefresh = backgroundRefresh { self.enableBackgroundRefresh = backgroundRefresh }
        self.lastModified = Date()
    }
    
    func addBackupHost(_ host: String) {
        guard !host.isEmpty && !backupHosts.contains(host) else { return }
        backupHosts.append(host)
        lastModified = Date()
    }
    
    func removeBackupHost(_ host: String) {
        backupHosts.removeAll { $0 == host }
        lastModified = Date()
    }
    
    func clearBackupHosts() {
        backupHosts.removeAll()
        lastModified = Date()
    }
    
    func resetToDefaults() {
        let defaultConfig = Configuration.defaultConfiguration()
        
        self.theme = defaultConfig.theme
        self.preferredLanguage = defaultConfig.preferredLanguage
        self.preferredCurrency = defaultConfig.preferredCurrency
        self.preferredChartType = defaultConfig.preferredChartType
        self.refreshInterval = defaultConfig.refreshInterval
        self.requestTimeout = defaultConfig.requestTimeout
        self.maxRetries = defaultConfig.maxRetries
        self.enableAnalytics = defaultConfig.enableAnalytics
        self.enableCrashReporting = defaultConfig.enableCrashReporting
        self.enableDebugMode = defaultConfig.enableDebugMode
        self.enablePushNotifications = defaultConfig.enablePushNotifications
        self.enableBackgroundRefresh = defaultConfig.enableBackgroundRefresh
        self.cacheEnabled = defaultConfig.cacheEnabled
        self.cacheTTL = defaultConfig.cacheTTL
        self.maxCacheSize = defaultConfig.maxCacheSize
        
        self.lastModified = Date()
    }
    
    func getHostForEnvironment() -> String {
        switch environment {
        case .development:
            return "https://dev-api.coindesk.com"
        case .staging:
            return "https://staging-api.coindesk.com"
        case .production:
            return apiHost
        }
    }
    
    func getSocketHostForEnvironment() -> String {
        switch environment {
        case .development:
            return "wss://dev-streamer.coindesk.com"
        case .staging:
            return "wss://staging-streamer.coindesk.com"
        case .production:
            return socketHost
        }
    }
    
    func getNextBackupHost() -> String? {
        guard hasBackupHosts else { return nil }
        // Simple round-robin selection
        let index = Int(Date().timeIntervalSince1970) % backupHosts.count
        return backupHosts[index]
    }
}

// MARK: - Validation
extension Configuration {
    var hasValidHosts: Bool {
        isValidURL(apiHost) && isValidURL(functionsHost) && isValidWebSocketURL(socketHost)
    }
    
    var hasValidAPIKey: Bool {
        !apiKey.isEmpty && apiKey.count >= 32 // Minimum API key length
    }
    
    var hasValidContactInfo: Bool {
        isValidEmail(supportEmail) && !companyName.isEmpty
    }
    
    var hasValidVersion: Bool {
        isValidSemVer(version) && !buildNumber.isEmpty
    }
    
    var hasValidSettings: Bool {
        refreshInterval > 0 && 
        requestTimeout > 0 && 
        maxRetries > 0 &&
        cacheTTL > 0 &&
        maxCacheSize > 0
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    private func isValidWebSocketURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "ws" || url.scheme == "wss"
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidSemVer(_ version: String) -> Bool {
        let semVerRegex = "^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"
        let semVerPredicate = NSPredicate(format: "SELF MATCHES %@", semVerRegex)
        return semVerPredicate.evaluate(with: version)
    }
    
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if !hasValidHosts {
            errors.append(.invalidHosts)
        }
        if !hasValidAPIKey {
            errors.append(.invalidAPIKey)
        }
        if !hasValidContactInfo {
            errors.append(.invalidContactInfo)
        }
        if !hasValidVersion {
            errors.append(.invalidVersion)
        }
        if !hasValidSettings {
            errors.append(.invalidSettings)
        }
        
        return errors
    }
}

// MARK: - Supporting Enums
enum AppEnvironment: String, CaseIterable, Codable, Sendable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    
    var displayName: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }
    
    var isDebugEnvironment: Bool {
        self != .production
    }
    
    var color: String {
        switch self {
        case .development: return "orange"
        case .staging: return "yellow"
        case .production: return "green"
        }
    }
}

enum AppTheme: String, CaseIterable, Codable, Sendable {
    case automatic = "automatic"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var systemImage: String {
        switch self {
        case .automatic: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

enum ValidationError: String, CaseIterable, LocalizedError {
    case invalidHosts = "invalid_hosts"
    case invalidAPIKey = "invalid_api_key"
    case invalidContactInfo = "invalid_contact_info"
    case invalidVersion = "invalid_version"
    case invalidSettings = "invalid_settings"
    
    var errorDescription: String? {
        switch self {
        case .invalidHosts:
            return "One or more host URLs are invalid"
        case .invalidAPIKey:
            return "API key is missing or invalid"
        case .invalidContactInfo:
            return "Contact information is incomplete or invalid"
        case .invalidVersion:
            return "Version information is invalid"
        case .invalidSettings:
            return "Configuration settings are invalid"
        }
    }
}


// MARK: - Codable
extension Configuration: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, apiHost, functionsHost, socketHost, backupHosts
        case sslCertificateData, companyName, apiKey
        case termsAndConditions, privacyPolicy, supportEmail
        case appStoreURL, websiteURL, version, buildNumber, minSupportedVersion
        case environment, theme, preferredLanguage, preferredCurrency, preferredChartType
        case refreshInterval, requestTimeout, maxRetries
        case enableAnalytics, enableCrashReporting, enableDebugMode
        case enablePushNotifications, enableBackgroundRefresh
        case cacheEnabled, cacheTTL, maxCacheSize
        case isDeleted, lastModified, createdAt
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let apiHost = try container.decode(String.self, forKey: .apiHost)
        let functionsHost = try container.decode(String.self, forKey: .functionsHost)
        let socketHost = try container.decode(String.self, forKey: .socketHost)
        let backupHosts = try container.decodeIfPresent([String].self, forKey: .backupHosts) ?? []
        let companyName = try container.decode(String.self, forKey: .companyName)
        let apiKey = try container.decode(String.self, forKey: .apiKey)
        let termsAndConditions = try container.decode(String.self, forKey: .termsAndConditions)
        let privacyPolicy = try container.decode(String.self, forKey: .privacyPolicy)
        let supportEmail = try container.decode(String.self, forKey: .supportEmail)
        let appStoreURL = try container.decodeIfPresent(String.self, forKey: .appStoreURL)
        let websiteURL = try container.decodeIfPresent(String.self, forKey: .websiteURL)
        let version = try container.decode(String.self, forKey: .version)
        let buildNumber = try container.decodeIfPresent(String.self, forKey: .buildNumber) ?? "1"
        let environment = try container.decodeIfPresent(AppEnvironment.self, forKey: .environment) ?? .production
        
        self.init(
            id: id,
            apiHost: apiHost,
            functionsHost: functionsHost,
            socketHost: socketHost,
            backupHosts: backupHosts,
            companyName: companyName,
            apiKey: apiKey,
            termsAndConditions: termsAndConditions,
            privacyPolicy: privacyPolicy,
            supportEmail: supportEmail,
            appStoreURL: appStoreURL,
            websiteURL: websiteURL,
            version: version,
            buildNumber: buildNumber,
            environment: environment
        )
        
        // Override with decoded values where available
        self.sslCertificateData = try container.decodeIfPresent(Data.self, forKey: .sslCertificateData)
        self.minSupportedVersion = try container.decodeIfPresent(String.self, forKey: .minSupportedVersion) ?? "1.0.0"
        self.theme = try container.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .automatic
        self.preferredLanguage = try container.decodeIfPresent(Language.self, forKey: .preferredLanguage) ?? .english
        self.preferredCurrency = try container.decodeIfPresent(String.self, forKey: .preferredCurrency) ?? "USD"
        self.preferredChartType = try container.decodeIfPresent(ChartType.self, forKey: .preferredChartType) ?? .line
        self.refreshInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .refreshInterval) ?? 30.0
        self.requestTimeout = try container.decodeIfPresent(TimeInterval.self, forKey: .requestTimeout) ?? 10.0
        self.maxRetries = try container.decodeIfPresent(Int.self, forKey: .maxRetries) ?? 3
        self.enableAnalytics = try container.decodeIfPresent(Bool.self, forKey: .enableAnalytics) ?? true
        self.enableCrashReporting = try container.decodeIfPresent(Bool.self, forKey: .enableCrashReporting) ?? true
        self.enableDebugMode = try container.decodeIfPresent(Bool.self, forKey: .enableDebugMode) ?? false
        self.enablePushNotifications = try container.decodeIfPresent(Bool.self, forKey: .enablePushNotifications) ?? true
        self.enableBackgroundRefresh = try container.decodeIfPresent(Bool.self, forKey: .enableBackgroundRefresh) ?? true
        self.cacheEnabled = try container.decodeIfPresent(Bool.self, forKey: .cacheEnabled) ?? true
        self.cacheTTL = try container.decodeIfPresent(TimeInterval.self, forKey: .cacheTTL) ?? 300.0
        self.maxCacheSize = try container.decodeIfPresent(Int.self, forKey: .maxCacheSize) ?? 100
        
        if let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) {
            self.createdAt = createdAt
        }
        if let lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) {
            self.lastModified = lastModified
        }
        if let isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) {
            self.isDeleted = isDeleted
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(apiHost, forKey: .apiHost)
        try container.encode(functionsHost, forKey: .functionsHost)
        try container.encode(socketHost, forKey: .socketHost)
        try container.encode(backupHosts, forKey: .backupHosts)
        try container.encodeIfPresent(sslCertificateData, forKey: .sslCertificateData)
        try container.encode(companyName, forKey: .companyName)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(termsAndConditions, forKey: .termsAndConditions)
        try container.encode(privacyPolicy, forKey: .privacyPolicy)
        try container.encode(supportEmail, forKey: .supportEmail)
        try container.encodeIfPresent(appStoreURL, forKey: .appStoreURL)
        try container.encodeIfPresent(websiteURL, forKey: .websiteURL)
        try container.encode(version, forKey: .version)
        try container.encode(buildNumber, forKey: .buildNumber)
        try container.encode(minSupportedVersion, forKey: .minSupportedVersion)
        try container.encode(environment, forKey: .environment)
        try container.encode(theme, forKey: .theme)
        try container.encode(preferredLanguage, forKey: .preferredLanguage)
        try container.encode(preferredCurrency, forKey: .preferredCurrency)
        try container.encode(preferredChartType, forKey: .preferredChartType)
        try container.encode(refreshInterval, forKey: .refreshInterval)
        try container.encode(requestTimeout, forKey: .requestTimeout)
        try container.encode(maxRetries, forKey: .maxRetries)
        try container.encode(enableAnalytics, forKey: .enableAnalytics)
        try container.encode(enableCrashReporting, forKey: .enableCrashReporting)
        try container.encode(enableDebugMode, forKey: .enableDebugMode)
        try container.encode(enablePushNotifications, forKey: .enablePushNotifications)
        try container.encode(enableBackgroundRefresh, forKey: .enableBackgroundRefresh)
        try container.encode(cacheEnabled, forKey: .cacheEnabled)
        try container.encode(cacheTTL, forKey: .cacheTTL)
        try container.encode(maxCacheSize, forKey: .maxCacheSize)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(lastModified, forKey: .lastModified)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Hashable & Equatable
extension Configuration: Hashable {
    static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum Language: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    case arabic = "ar"
    case hindi = "hi"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "中文"
        case .arabic: return "العربية"
        case .hindi: return "हिन्दी"
        }
    }
    
    var locale: Locale {
        Locale(identifier: rawValue)
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .russian: return "🇷🇺"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .arabic: return "🇸🇦"
        case .hindi: return "🇮🇳"
        }
    }
    
    var isRTL: Bool {
        self == .arabic
    }
}


enum ChartType: String, CaseIterable, Codable, Sendable {
    case line = "line"
    case candlestick = "candlestick"
    case area = "area"
    case ohlc = "ohlc"
    case volume = "volume"
    case mountain = "mountain"
    
    var displayName: String {
        switch self {
        case .line: return "Line"
        case .candlestick: return "Candlestick"
        case .area: return "Area"
        case .ohlc: return "OHLC"
        case .volume: return "Volume"
        case .mountain: return "Mountain"
        }
    }
    
    var systemImage: String {
        switch self {
        case .line: return "chart.line.uptrend.xyaxis"
        case .candlestick: return "chart.bar.fill"
        case .area: return "chart.line.flattrend.xyaxis.fill"
        case .ohlc: return "chart.bar"
        case .volume: return "chart.bar.xaxis"
        case .mountain: return "mountain.2.fill"
        }
    }
    
    var description: String {
        switch self {
        case .line:
            return "Simple line chart showing price movement"
        case .candlestick:
            return "Detailed view with open, high, low, close prices"
        case .area:
            return "Filled area chart highlighting price trends"
        case .ohlc:
            return "Open-High-Low-Close bar chart"
        case .volume:
            return "Trading volume visualization"
        case .mountain:
            return "Gradient-filled mountain-style chart"
        }
    }
    
    var requiresOHLCData: Bool {
        switch self {
        case .candlestick, .ohlc:
            return true
        case .line, .area, .volume, .mountain:
            return false
        }
    }
    
    var requiresVolumeData: Bool {
        self == .volume
    }
}