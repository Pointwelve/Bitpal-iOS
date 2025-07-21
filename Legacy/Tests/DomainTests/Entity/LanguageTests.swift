//
//  LanguageTests.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class LanguageTests: XCTestCase {
   func testDefaultLanguageIsEnglish() {
      XCTAssertEqual(Language.default, .en)
   }

   func testInitWithInvalidCodeResultsInEnglish() {
      XCTAssertEqual(Language(code: "ZZ"), .en)
   }

   func testListIsEqual() {
      let a = LanguageList(defaultLanguage: .en, languages: [.en, .de, .fr])
      let b = LanguageList(defaultLanguage: .en, languages: [.en, .de, .fr])
      XCTAssertEqual(a, b)
   }

   func testListIsNotEqualIfLanguagesAreDifferent() {
      let a = LanguageList(defaultLanguage: .en, languages: [.en, .de, .fr])
      let b = LanguageList(defaultLanguage: .en, languages: [.en, .fr])
      XCTAssertNotEqual(a, b)
   }
}
