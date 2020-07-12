//
//  ExchangeTests.swift
//  Domain
//
//  Created by Li Hao Lai on 16/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class ExchangeTests: XCTestCase {
   func testExchangeEquality() {
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")
      let exchangeB = Exchange(id: "Gemini", name: "Gemini renamed")

      XCTAssertNotEqual(exchangeA, exchangeB)
   }
}
