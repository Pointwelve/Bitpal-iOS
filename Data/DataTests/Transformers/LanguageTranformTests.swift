//
//  LanguageTranformTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import Foundation
import XCTest

class LanguageTranformTests: XCTestCase {
   func testDefaultLanguageDataIsSameAsDefaultLanguageDomain() {
      XCTAssertEqual(Language.default.rawValue, LanguageData.default.code)
   }

   func testTranformingToLanguageFromLanguageData() {
      let data = LanguageData.default
      let domain = data.asDomain()

      XCTAssertEqual(data.code, domain.rawValue)
   }
}
