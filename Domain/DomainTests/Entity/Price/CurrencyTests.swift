//
//  CurrencyTests.swift
//  Domain
//
//  Created by Li Hao Lai on 6/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class CurrencyTests: XCTestCase {
   func testCurrencyEquality() {
      let currencyA = Currency(id: "ANT", name: "Aragon", symbol: "ANT")
      let currencyB = Currency(id: "ANT", name: "Aragon renamed", symbol: "ANTXXX")

      XCTAssertNotEqual(currencyA, currencyB)
   }
}
