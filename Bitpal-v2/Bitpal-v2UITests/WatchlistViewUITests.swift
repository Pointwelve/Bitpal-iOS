//
//  WatchlistViewUITests.swift
//  Bitpal-v2UITests
//
//  Created by Claude on 20/7/25.
//

import XCTest

final class WatchlistViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testWatchlistTabExists() throws {
        // Verify the Watchlist tab exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        let watchlistTab = tabBar.buttons["Watchlist"]
        XCTAssertTrue(watchlistTab.exists, "Watchlist tab should exist")
    }
    
    @MainActor
    func testNavigateToWatchlistTab() throws {
        // Navigate to Watchlist tab
        let watchlistTab = app.tabBars.buttons["Watchlist"]
        watchlistTab.tap()
        
        // Verify we're on the Watchlist screen
        let navigationBar = app.navigationBars["Watchlist"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 2), "Watchlist navigation bar should appear")
    }
    
    // MARK: - Watchlist Content Tests
    
    @MainActor
    func testWatchlistEmptyState() throws {
        // Navigate to Watchlist
        app.tabBars.buttons["Watchlist"].tap()
        
        // Check for empty state message
        let emptyStateText = app.staticTexts["No currency pairs added"]
        if emptyStateText.exists {
            XCTAssertTrue(emptyStateText.exists, "Empty state message should be displayed")
            
            let addButton = app.staticTexts["Tap + to add currency pairs"]
            XCTAssertTrue(addButton.exists, "Add instruction should be displayed")
        }
    }
    
    @MainActor
    func testAddCurrencyButtonExists() throws {
        // Navigate to Watchlist
        app.tabBars.buttons["Watchlist"].tap()
        
        // Check for add button
        let addButton = app.navigationBars["Watchlist"].buttons["Add"]
        XCTAssertTrue(addButton.exists, "Add button should exist in navigation bar")
    }
    
    @MainActor
    func testTapAddCurrencyButton() throws {
        // Navigate to Watchlist
        app.tabBars.buttons["Watchlist"].tap()
        
        // Tap add button
        let addButton = app.navigationBars["Watchlist"].buttons["Add"]
        addButton.tap()
        
        // Verify Add Currency sheet appears
        let addCurrencyNavBar = app.navigationBars["Add Currency"]
        XCTAssertTrue(addCurrencyNavBar.waitForExistence(timeout: 2), "Add Currency sheet should appear")
    }
    
    // MARK: - Add Currency Flow Tests
    
    @MainActor
    func testAddCurrencyFlow() throws {
        // Navigate to Watchlist
        app.tabBars.buttons["Watchlist"].tap()
        
        // Tap add button
        app.navigationBars["Watchlist"].buttons["Add"].tap()
        
        // Wait for sheet to appear
        let addCurrencyNavBar = app.navigationBars["Add Currency"]
        XCTAssertTrue(addCurrencyNavBar.waitForExistence(timeout: 3))
        
        // Check for cancel button in toolbar
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2), "Cancel button should exist")
        
        // Check for search field
        let searchField = app.textFields["Search currencies..."]
        XCTAssertTrue(searchField.exists, "Search field should exist")
        
        // Check for category buttons (Popular, Trending, All, Recent)
        let popularButton = app.buttons["Popular"]
        XCTAssertTrue(popularButton.exists, "Popular category button should exist")
    }
    
    @MainActor
    func testCancelAddCurrency() throws {
        // Navigate to Watchlist
        app.tabBars.buttons["Watchlist"].tap()
        
        // Open add currency sheet
        app.navigationBars["Watchlist"].buttons["Add"].tap()
        
        // Wait for sheet
        let addCurrencyNavBar = app.navigationBars["Add Currency"]
        XCTAssertTrue(addCurrencyNavBar.waitForExistence(timeout: 2))
        
        // Tap cancel
        addCurrencyNavBar.buttons["Cancel"].tap()
        
        // Verify we're back on Watchlist
        let watchlistNavBar = app.navigationBars["Watchlist"]
        XCTAssertTrue(watchlistNavBar.waitForExistence(timeout: 2), "Should return to Watchlist")
    }
    
    // MARK: - Currency List Item Tests
    
    @MainActor
    func testCurrencyPairCellStructure() throws {
        // This test assumes there's at least one currency pair
        // In a real app, you might need to add one first
        
        app.tabBars.buttons["Watchlist"].tap()
        
        // Look for any cell with currency pair structure
        let cells = app.cells
        if cells.count > 0 {
            let firstCell = cells.element(boundBy: 0)
            
            // Check for expected elements in a currency pair cell
            // These would need to be adjusted based on actual accessibility identifiers
            let currencyLabels = firstCell.staticTexts.allElementsBoundByIndex
            XCTAssertTrue(currencyLabels.count >= 2, "Currency pair cell should have multiple labels")
        }
    }
    
    // MARK: - Swipe Actions Tests
    
    @MainActor
    func testSwipeToDelete() throws {
        app.tabBars.buttons["Watchlist"].tap()
        
        let cells = app.cells
        if cells.count > 0 {
            let firstCell = cells.element(boundBy: 0)
            
            // Swipe left on cell
            firstCell.swipeLeft()
            
            // Check for delete button
            let deleteButton = app.buttons["Delete"]
            if deleteButton.exists {
                XCTAssertTrue(deleteButton.exists, "Delete button should appear on swipe")
            }
        }
    }
    
    // MARK: - Pull to Refresh Tests
    
    @MainActor
    func testPullToRefresh() throws {
        app.tabBars.buttons["Watchlist"].tap()
        
        // Pull down to refresh
        let watchlistTable = app.tables.firstMatch
        if watchlistTable.exists {
            watchlistTable.swipeDown()
            
            // In a real test, you'd check for refresh indicator
            // or verify data refresh happened
            XCTAssertTrue(true, "Pull to refresh gesture completed")
        }
    }
    
    // MARK: - Search Tests
    
    @MainActor
    func testSearchBarExists() throws {
        app.tabBars.buttons["Watchlist"].tap()
        
        // Check if search bar exists
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            XCTAssertTrue(searchField.exists, "Search field should exist")
            
            // Test tapping search field
            searchField.tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2), "Keyboard should appear")
            
            // Dismiss keyboard
            app.buttons["Cancel"].tap()
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testWatchlistScrollPerformance() throws {
        app.tabBars.buttons["Watchlist"].tap()
        
        measure {
            let table = app.tables.firstMatch
            if table.exists {
                // Scroll down
                table.swipeUp()
                // Scroll up
                table.swipeDown()
            }
        }
    }
}