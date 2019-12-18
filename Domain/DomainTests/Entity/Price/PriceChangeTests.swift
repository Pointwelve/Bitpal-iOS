//
//  PriceChangeTests.swift
//  Domain
//
//  Created by James Lai on 7/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class PriceChangeTests: XCTestCase {
   func testPercentageIsEqualUp() {
      XCTAssertEqual(PriceChange.priceChange(with: 10.0), PriceChange.up)
   }

   func testPercentageIsEqualDown() {
      XCTAssertEqual(PriceChange.priceChange(with: -10.0), PriceChange.down)
   }

   func testPercentageIsEqualUnchanged() {
      XCTAssertEqual(PriceChange.priceChange(with: 0.0), PriceChange.unchanged)
   }
}
