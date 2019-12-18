//
//  AppUITests.swift
//  AppUITests
//
//  Created by Ryne Cheow on 7/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import XCTest

class AppUITests: XCTestCase {

   override func setUp() {
      super.setUp()

      // Put setup code here. This method is called before the invocation of each test method in the class.

      // In UI tests it is usually best to stop immediately when a failure occurs.
      continueAfterFailure = false
      // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
      XCUIApplication().launch()

      // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
   }

   override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
      super.tearDown()
   }

   func testFirstLaunch() {
      let app = XCUIApplication()

      // Make sure watchlist is empty and error shows
      let errorTitle = app.staticTexts["loadStateErrorViewTitle"]
      let errorMessage = app.staticTexts["loadStateErrorViewMessage"]

      XCTAssert(errorTitle.exists)
      XCTAssert(errorTitle.label == "WATCHLIST IS EMPTY")

      XCTAssert(errorMessage.exists)
      XCTAssert(errorMessage.label == "Tap '+' to add cryptocurrency pairs to your watchlist.")

      // Make sure tab bar well formed
      let tabBarsQuery = app.tabBars["tabBar"]
      XCTAssertEqual(tabBarsQuery.frame.height, 50)
      XCTAssert(tabBarsQuery.buttons["watchlistTab"].exists)
      XCTAssert(tabBarsQuery.buttons["watchlistTab"].isSelected)

      XCTAssert(tabBarsQuery.buttons["settingsTab"].exists)
      XCTAssert(!tabBarsQuery.buttons["settingsTab"].isSelected)

      // Make sure watchlist navigation bar well formed
      let watchlistNavigationBar = XCUIApplication().navigationBars["Watchlist"]
      XCTAssertEqual(watchlistNavigationBar.frame.height, 44)
      XCTAssert(watchlistNavigationBar.staticTexts["watchlistTitle"].exists)
      XCTAssert(watchlistNavigationBar.buttons["watchlistAddButton"].exists)

      // Go to settings tab
      app.tabBars["tabBar"].buttons["settingsTab"].tap()

      // Check navigation bar
      let settingsNavigationBar = app.navigationBars["Settings"]
      XCTAssertEqual(settingsNavigationBar.frame.height, 44)
      XCTAssert(settingsNavigationBar.staticTexts["settingsNavigationTitle"].exists)

      // Make sure tab bar still well formed
      XCTAssertEqual(tabBarsQuery.frame.height, 50)
      XCTAssert(tabBarsQuery.buttons["watchlistTab"].exists)
      XCTAssert(!tabBarsQuery.buttons["watchlistTab"].isSelected)

      XCTAssert(tabBarsQuery.buttons["settingsTab"].exists)
      XCTAssert(tabBarsQuery.buttons["settingsTab"].isSelected)

      // Check for settings table
      let tablesQuery = app.tables["settingsTable"]
      XCTAssert(tablesQuery.exists)

      // Make sure terms and condition cell well formed
      let termsAndConditionCell = tablesQuery.cells["termsAndConditionCell"]
      XCTAssert(termsAndConditionCell.exists)
      XCTAssert(termsAndConditionCell.staticTexts["settingsCellTitleLabel"].exists)
      XCTAssert(!termsAndConditionCell.staticTexts["settingsCellDescriptionLabel"].exists)

      let languageCell = tablesQuery.cells["languageCell"]
      XCTAssert(languageCell.exists)
      XCTAssert(languageCell.staticTexts["settingsCellTitleLabel"].exists)
      XCTAssert(languageCell.staticTexts["settingsCellDescriptionLabel"].exists)

      let styleCell = tablesQuery.cells["styleCell"]
      XCTAssert(styleCell.exists)
      XCTAssert(styleCell.staticTexts["settingsCellTitleLabel"].exists)
      XCTAssert(styleCell.staticTexts["settingsCellDescriptionLabel"].exists)

      // Tap terms and condition cell
      termsAndConditionCell.tap()

      let termsAndConditionsNavigationBar = app.navigationBars["Terms and Conditions"]
      XCTAssert(termsAndConditionsNavigationBar.staticTexts["staticContentNavigationTitle"].exists)

      XCTAssert(app.staticTexts["staticContentCompanyTitleLabel"].exists)
      XCTAssert(app.textViews["staticContentTextView"].exists)

      termsAndConditionsNavigationBar.buttons["Back"].tap()

   }
}
