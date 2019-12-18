//
//  PriceListTransformTests.swift
//  Data
//
//  Created by Hong on 16/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import XCTest

class CurrencyPairListTransformTests: XCTestCase {
   func testPriceListAsData() {
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchange = Exchange(id: "Gemini", name: "Gemini")

      let currencyDataA = CurrencyData(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyDataB = CurrencyData(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeData = ExchangeData(id: "Gemini", name: "Gemini")

      let date = Date()

      let currencyPair = CurrencyPairGroup(id: "", baseCurrency: currencyA, quoteCurrency: currencyB, exchanges: [exchange])

      let currencyPairList = CurrencyPairList(id: "PriceList", currencyPairs: [currencyPair], modifyDate: date)

      let currencyPairData = CurrencyPairGroupData(id: "", baseCurrency: currencyDataA, quoteCurrency: currencyDataB, exchanges: [exchangeData])
      let currencyPairListData = CurrencyPairListData(id: "PriceList", currencyPairs: [currencyPairData], modifyDate: date)

      XCTAssertTrue(currencyPairList.asData() == currencyPairListData)
      XCTAssertTrue(currencyPairList == currencyPairListData.asDomain())
   }
}
