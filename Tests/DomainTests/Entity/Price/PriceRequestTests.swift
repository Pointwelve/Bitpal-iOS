//
//  PriceRequestTests.swift
//  Domain
//
//  Created by Li Hao Lai on 15/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class PriceRequestTests: XCTestCase {
   func testPriceListRequestIsEqual() {
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyC = Currency(id: "ETH", name: "Ethereum", symbol: "ETH")
      let exchange = Exchange(id: "Gemini", name: "Gemini")
      let pairs = [
         CurrencyPair(baseCurrency: currencyA,
                      quoteCurrency: currencyB, exchange: exchange, price: 1.0),
         CurrencyPair(baseCurrency: currencyC,
                      quoteCurrency: currencyB, exchange: exchange, price: 1.0)
      ]
      let a = GetPriceListRequest(currencyPairs: pairs)
      let b = GetPriceListRequest(currencyPairs: pairs)
      XCTAssertEqual(a, b)
   }

   func testPriceListRequestIsNotEqualIfExchangeIsDifferent() {
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyC = Currency(id: "ETH", name: "Ethereum", symbol: "ETH")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")
      let exchangeB = Exchange(id: "HitBTC", name: "HitBTC")

      let pairsA = [
         CurrencyPair(baseCurrency: currencyA,
                      quoteCurrency: currencyB, exchange: exchangeA, price: 1.0),
         CurrencyPair(baseCurrency: currencyC,
                      quoteCurrency: currencyC, exchange: exchangeA, price: 1.0)
      ]
      let pairsB = [
         CurrencyPair(baseCurrency: currencyA,
                      quoteCurrency: currencyB, exchange: exchangeB, price: 1.0),
         CurrencyPair(baseCurrency: currencyC,
                      quoteCurrency: currencyC, exchange: exchangeB, price: 1.0)
      ]
      let a = GetPriceListRequest(currencyPairs: pairsA)
      let b = GetPriceListRequest(currencyPairs: pairsB)
      XCTAssertNotEqual(a, b)
   }

   func testHistoricalPriceListRequestIsEqual() {
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let a = HistoricalPriceListRequest(fromSymbol: currencyA,
                                         toSymbol: currencyB,
                                         exchange: exchangeA, aggregate: 6,
                                         limit: 120,
                                         routerType: .day)

      let b = HistoricalPriceListRequest(fromSymbol: currencyA,
                                         toSymbol: currencyB,
                                         exchange: exchangeA, aggregate: 6,
                                         limit: 120,
                                         routerType: .day)
      XCTAssertEqual(a, b)
   }

   func testHistoricalPriceListRequestIsNotEqualIfExchangeIsDifferent() {
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")
      let exchangeB = Exchange(id: "CoinBase", name: "CoinBase")

      let a = HistoricalPriceListRequest(fromSymbol: currencyA,
                                         toSymbol: currencyB,
                                         exchange: exchangeB, aggregate: 6,
                                         limit: 120,
                                         routerType: .day)
      let b = HistoricalPriceListRequest(fromSymbol: currencyA,
                                         toSymbol: currencyB,
                                         exchange: exchangeA, aggregate: 6,
                                         limit: 120,
                                         routerType: .day)
      XCTAssertNotEqual(a, b)
   }

   func testHistoricalPriceListRequestIsNotEqualIfRouterTypeIsDifferent() {
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")
      let exchangeB = Exchange(id: "CoinBase", name: "CoinBase")

      let a = HistoricalPriceListRequest(fromSymbol: currencyA,
                                         toSymbol: currencyB,
                                         exchange: exchangeB, aggregate: 6,
                                         limit: 120,
                                         routerType: .day)
      let b = HistoricalPriceListRequest(fromSymbol: currencyA,
                                         toSymbol: currencyB,
                                         exchange: exchangeA, aggregate: 6,
                                         limit: 120,
                                         routerType: .hour)
      XCTAssertNotEqual(a, b)
   }

   func testHistoricalPriceListRequestIsNotEqualIfIsAllDataIsDifferent() {
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")
      let exchangeB = Exchange(id: "CoinBase", name: "CoinBase")

      let a = HistoricalPriceListRequest(fromSymbol: currencyA,
                                         toSymbol: currencyB,
                                         exchange: exchangeB, aggregate: 6,
                                         limit: 120,
                                         routerType: .day)
      let b = HistoricalPriceListRequest(fromSymbol: currencyA,
                                         toSymbol: currencyB,
                                         exchange: exchangeA, aggregate: 6,
                                         limit: 120,
                                         routerType: .hour)
      XCTAssertNotEqual(a, b)
   }
}
