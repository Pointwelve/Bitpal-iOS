//
//  SettingsModelTests.swift
//  Bitpal-v2Tests
//
//  Created by Ryne Cheow on 20/7/25.
//

import XCTest
import SwiftData
@testable import Bitpal_v2

@MainActor
final class SettingsModelTests: XCTestCase {
    
    private var container: ModelContainer!
    private var context: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Configuration.self, UserPreferences.self,
            configurations: config
        )
        context = container.mainContext
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testConfiguration_Creation() throws {
        let config = Configuration()
        config.apiHost = "api.test.com"
        config.socketHost = "ws.test.com"
        config.companyName = "Test Company"
        config.version = "1.0.0"
        config.apiKey = "test-key"
        
        context.insert(config)
        try context.save()
        
        XCTAssertEqual(config.apiHost, "api.test.com")
        XCTAssertEqual(config.socketHost, "ws.test.com")
        XCTAssertEqual(config.companyName, "Test Company")
        XCTAssertEqual(config.version, "1.0.0")
        XCTAssertEqual(config.apiKey, "test-key")
    }
    
    func testConfiguration_Update() throws {
        let config = Configuration()
        config.apiKey = "old-key"
        context.insert(config)
        try context.save()
        
        config.apiKey = "new-key"
        try context.save()
        
        XCTAssertEqual(config.apiKey, "new-key")
    }
    
    // MARK: - UserPreferences Tests
    
    func testUserPreferences_Creation() throws {
        let preferences = UserPreferences()
        context.insert(preferences)
        try context.save()
        
        XCTAssertEqual(preferences.currency, "USD")
        XCTAssertEqual(preferences.theme, "system")
        XCTAssertTrue(preferences.notificationsEnabled)
        XCTAssertTrue(preferences.priceAlertsEnabled)
        XCTAssertFalse(preferences.newsAlertsEnabled)
        XCTAssertFalse(preferences.biometricAuthEnabled)
    }
    
    func testUserPreferences_Updates() throws {
        let preferences = UserPreferences()
        context.insert(preferences)
        try context.save()
        
        preferences.currency = "EUR"
        preferences.theme = "dark"
        preferences.notificationsEnabled = false
        try context.save()
        
        XCTAssertEqual(preferences.currency, "EUR")
        XCTAssertEqual(preferences.theme, "dark")
        XCTAssertFalse(preferences.notificationsEnabled)
    }
    
    // MARK: - Theme Tests
    
    func testTheme_AllCases() {
        let themes = Theme.allCases
        XCTAssertEqual(themes.count, 3)
        XCTAssertTrue(themes.contains(.light))
        XCTAssertTrue(themes.contains(.dark))
        XCTAssertTrue(themes.contains(.system))
    }
    
    func testTheme_DisplayNames() {
        XCTAssertEqual(Theme.light.displayName, "Light")
        XCTAssertEqual(Theme.dark.displayName, "Dark")
        XCTAssertEqual(Theme.system.displayName, "System")
    }
    
    func testTheme_RawValues() {
        XCTAssertEqual(Theme.light.rawValue, "light")
        XCTAssertEqual(Theme.dark.rawValue, "dark")
        XCTAssertEqual(Theme.system.rawValue, "system")
    }
}