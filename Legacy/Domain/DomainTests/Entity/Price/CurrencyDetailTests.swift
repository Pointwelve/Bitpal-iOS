//
//  CurrencyDetailTests.swift
//  Domain
//
//  Created by Kok Hong Choo on 28/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class CurrencyDetailTests: XCTestCase {
   func testCurrencyDetailEqual() {
      let date = Date()
      let a = CurrencyDetail(fromCurrency: "ETH",
                             toCurrency: "BTC",
                             price: 10.0,
                             volume24Hour: 0.0,
                             open24Hour: 0.0,
                             high24Hour: 0.0,
                             low24Hour: 0.0,
                             change24Hour: 0.0,
                             changePct24hour: 0.0,
                             fromDisplaySymbol: "a",
                             toDisplaySymbol: "b",
                             marketCap: 40.0,
                             exchange: "Gemini",
                             modifyDate: date)

      let b = CurrencyDetail(fromCurrency: "ETH",
                             toCurrency: "BTC",
                             price: 10.0,
                             volume24Hour: 0.0,
                             open24Hour: 0.0,
                             high24Hour: 0.0,
                             low24Hour: 0.0,
                             change24Hour: 0.0,
                             changePct24hour: 0.0,
                             fromDisplaySymbol: "a",
                             toDisplaySymbol: "b",
                             marketCap: 40.0,
                             exchange: "Gemini",
                             modifyDate: date)

      XCTAssertEqual(a, b)
   }

   func testCurrencyDetailNotEqual() {
      let date = Date()
      let a = CurrencyDetail(fromCurrency: "ETH",
                             toCurrency: "BTC",
                             price: 10.0,
                             volume24Hour: 0.0,
                             open24Hour: 0.0,
                             high24Hour: 0.0,
                             low24Hour: 0.0,
                             change24Hour: 0.0,
                             changePct24hour: 0.0,
                             fromDisplaySymbol: "a",
                             toDisplaySymbol: "b",
                             marketCap: 40.0,
                             exchange: "Gemini",
                             modifyDate: date)

      let b = CurrencyDetail(fromCurrency: "ETH",
                             toCurrency: "BTC",
                             price: 10.0,
                             volume24Hour: 0.0,
                             open24Hour: 0.0,
                             high24Hour: 0.0,
                             low24Hour: 343.0,
                             change24Hour: 0.0,
                             changePct24hour: 0.0,
                             fromDisplaySymbol: "a",
                             toDisplaySymbol: "b",
                             marketCap: 40.0,
                             exchange: "Gemini",
                             modifyDate: date)

      XCTAssertNotEqual(a, b)
   }

   func testCurrencyDetailNotEqual2() {
      let date = Date()
      let a = CurrencyDetail(fromCurrency: "AADDDD",
                             toCurrency: "BTC",
                             price: 10.0,
                             volume24Hour: 0.0,
                             open24Hour: 0.0,
                             high24Hour: 0.0,
                             low24Hour: 0.0,
                             change24Hour: 0.0,
                             changePct24hour: 0.0,
                             fromDisplaySymbol: "a",
                             toDisplaySymbol: "b",
                             marketCap: 40.0,
                             exchange: "Gemini",
                             modifyDate: date)

      let b = CurrencyDetail(fromCurrency: "ETH",
                             toCurrency: "BTC",
                             price: 10.0,
                             volume24Hour: 0.0,
                             open24Hour: 0.0,
                             high24Hour: 0.0,
                             low24Hour: 0.0,
                             change24Hour: 0.0,
                             changePct24hour: 0.0,
                             fromDisplaySymbol: "a",
                             toDisplaySymbol: "b",
                             marketCap: 40.0,
                             exchange: "Gemini",
                             modifyDate: date)

      XCTAssertNotEqual(a, b)
   }
}
