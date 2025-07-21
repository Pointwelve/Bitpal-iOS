//
//  StringExt-Tests.swift
//  DomainTests
//
//  Created by Li Hao Lai on 11/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import XCTest

class StringExt_Tests: XCTestCase {
   func testPriceFormatting() {
      let currentPrice = "4768.86"
      let maxLength = currentPrice.count + 2
      let maxSignificant = { () -> Int in
         let split = currentPrice.components(separatedBy: ".")
         if split.count == 2 {
            return split[1].count + 2
         }

         return 2
      }()

      let testPrice = "4768.8633"

      guard let valid = testPrice.format(nil, maxLength: maxLength, maxSignificant: maxSignificant) else {
         XCTFail()
         return
      }

      XCTAssertTrue(valid == testPrice)

      let testPrice2 = "476855.86"

      guard let valid2 = testPrice2.format(nil, maxLength: maxLength, maxSignificant: maxSignificant) else {
         XCTFail()
         return
      }

      XCTAssertTrue(valid2 == testPrice2)

      let testPrice3 = "4768.863366"

      if testPrice3.format(nil, maxLength: maxLength, maxSignificant: maxSignificant) != nil {
         XCTFail()
      }
   }
}
