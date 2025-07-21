//
//  PreferencesTests.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class PreferencesTests: XCTestCase {
   func testPreferencesMapping() {
      let preferences = Preferences(language: .en, databaseName: "TestName")
      XCTAssertEqual(preferences.language, .en)
      XCTAssertEqual(preferences.databaseName, "TestName")
   }

   func testPreferencesEquality() {
      let preferencesA = Preferences(language: .en, databaseName: "TestName")
      let preferencesB = Preferences(language: .en, databaseName: "TestName")
      XCTAssertEqual(preferencesA, preferencesB)
   }

   func testPreferencesLanguageNotEqual() {
      let preferencesA = Preferences(language: .fr, databaseName: "TestName")
      let preferencesB = Preferences(language: .en, databaseName: "TestName")
      XCTAssertNotEqual(preferencesA, preferencesB)
   }

   func testPreferencesDatabaseNameNotEqual() {
      let preferencesA = Preferences(language: .en, databaseName: "TestName")
      let preferencesB = Preferences(language: .en, databaseName: "TestNameB")
      XCTAssertNotEqual(preferencesA, preferencesB)
   }
}
