//
//  CurrencyPairTests.swift
//  Domain
//
//  Created by James Lai on 7/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class CurrencyPairTests: XCTestCase {
   func testCurrencyPairReciprocalPrice() {
      let currencyA = Currency(id: "ANT", name: "Aragon", symbol: "ANT")
      let currencyB = Currency(id: "ETH", name: "Ethereum", symbol: "ETH")
      let exchange = Exchange(id: "ETH", name: "Bittrex")
      let a = CurrencyPair(baseCurrency: currencyA, quoteCurrency: currencyB, exchange: exchange, price: 1.0)
      let reciprocalPrice = a.reciprocalPrice

      XCTAssertEqual(1 / a.price, reciprocalPrice)
   }

   func testCurrencyPairFlipped() {
      let currencyA = Currency(id: "ANT", name: "Aragon", symbol: "ANT")
      let currencyB = Currency(id: "ETH", name: "Ethereum", symbol: "ETH")
      let exchange = Exchange(id: "ETH", name: "Bittrex")
      let a = CurrencyPair(baseCurrency: currencyA, quoteCurrency: currencyB, exchange: exchange, price: 1.0)
      let b = a.flipped()

      XCTAssertEqual(a.baseCurrency, b.quoteCurrency)
      XCTAssertEqual(a.quoteCurrency, b.baseCurrency)
   }

   func testCurrencyPairPrimaryKey() {
      let currencyA = Currency(id: "ANT", name: "Aragon", symbol: "ANT")
      let currencyB = Currency(id: "ETH", name: "Ethereum", symbol: "ETH")
      let exchange = Exchange(id: "ETH", name: "Bittrex")
      let a = CurrencyPair(baseCurrency: currencyA, quoteCurrency: currencyB, exchange: exchange, price: 1.0)

      XCTAssertEqual(a.primaryKey, "\(a.baseCurrency.name)\(a.quoteCurrency.name)\(a.exchange.name)")
   }
}
