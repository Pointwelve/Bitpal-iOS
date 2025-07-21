//
//  PreferencesTranformTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import XCTest

class PreferencesTranformTests: XCTestCase {
   func testTranformingToPreferencesFromPreferencesData() {
      let preferencesDataType = PreferencesData(language: Language.en.asData(),
                                                theme: try! ThemeData(name: "dark"),
                                                databaseName: "blah",
                                                installed: true,
                                                chartType: 0)
      let preferences = preferencesDataType.asDomain()

      XCTAssertEqual(Language.en, preferences.language)
      XCTAssertEqual(Theme.dark, preferences.theme)
      XCTAssertEqual("blah", preferences.databaseName)
      XCTAssertEqual(true, preferences.installed)
   }

   func testTranformingToPreferencesFromPreferencesDataWithNilDatabase() {
      let preferencesDataType = PreferencesData(language: Language.en.asData(),
                                                theme: try! ThemeData(name: "dark"),
                                                databaseName: nil,
                                                installed: true,
                                                chartType: 0)
      let preferences = preferencesDataType.asDomain()

      XCTAssertEqual(Language.en, preferences.language)
      XCTAssertEqual(Theme.dark, preferences.theme)
      XCTAssertNil(preferences.databaseName)
      XCTAssertEqual(true, preferences.installed)
   }

   func testTranformingToPreferencesDataFromPreferences() {
      let preferences = Preferences(language: Language.en,
                                    theme: .dark,
                                    databaseName: "blah",
                                    installed: true,
                                    chartType: .line)
      let preferencesDataType = preferences.asData()

      XCTAssertEqual(Language.en.asData().code, preferencesDataType.language?.code)
      XCTAssertEqual("blah", preferencesDataType.databaseName)
      XCTAssertEqual(true, preferencesDataType.installed)
      XCTAssertEqual(Theme.dark.asData().name, preferencesDataType.theme?.name)
   }

   func testTranformingToPreferencesDataFromPreferencesWithNilDatabase() {
      let preferences = Preferences(language: Language.en, databaseName: nil, installed: true)
      let preferencesDataType = preferences.asData()

      XCTAssertEqual(Language.en.asData().code, preferencesDataType.language?.code)
      XCTAssertNil(preferencesDataType.databaseName)
      XCTAssertEqual(true, preferencesDataType.installed)
   }

   func testPreferencesDataSerialisation() {
      let preferencesData = PreferencesData(language: Language.en.asData(),
                                            theme: try! ThemeData(name: "dark"),
                                            databaseName: "Database",
                                            installed: true,
                                            chartType: 0)

      let preferencesSerialized: [String: Any] = preferencesData.serialized()

      XCTAssertEqual(preferencesSerialized["language"] as? String, Language.en.rawValue)
      XCTAssertEqual(preferencesSerialized["databaseName"] as? String, "Database")
      XCTAssertEqual(true, preferencesSerialized["installed"] as! Bool)
      XCTAssertEqual(Theme.dark.rawValue, preferencesSerialized["theme"] as? String)

      guard let preferencesRedeserialised = try? PreferencesData.deserialize(data: preferencesSerialized) else {
         XCTFail()
         return
      }

      XCTAssertEqual(preferencesRedeserialised, preferencesData)
   }
}
