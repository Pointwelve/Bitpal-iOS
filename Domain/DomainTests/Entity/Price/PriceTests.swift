//
//  PriceTests.swift
//  Domain
//
//  Created by Li Hao Lai on 15/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class PriceTests: XCTestCase {
   func testPriceIsEqual() {
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let a = CurrencyPair(baseCurrency: currencyA,
                           quoteCurrency: currencyB,
                           exchange: exchangeA,
                           price: 1.0)
      let b = CurrencyPair(baseCurrency: currencyA,
                           quoteCurrency: currencyB,
                           exchange: exchangeA,
                           price: 1.0)
      XCTAssertEqual(a, b)
   }

   func testPriceListIsNotEqual() {
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyC = Currency(id: "ETH", name: "Ethereum", symbol: "ETH")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let a = CurrencyPairList(id: "PriceList", currencyPairs: [
         CurrencyPairGroup(id: "BTC_USD",
                           baseCurrency: currencyA,
                           quoteCurrency: currencyB,
                           exchanges: [exchangeA]),
         CurrencyPairGroup(id: "ETH_USD",
                           baseCurrency: currencyC,
                           quoteCurrency: currencyB,
                           exchanges: [exchangeA])
      ], modifyDate: Date())
      let b = CurrencyPairList(id: "PriceList", currencyPairs: [
         CurrencyPairGroup(id: "BTC_USD",
                           baseCurrency: currencyA,
                           quoteCurrency: currencyB,
                           exchanges: [exchangeA]),
         CurrencyPairGroup(id: "ETH_USD",
                           baseCurrency: currencyC,
                           quoteCurrency: currencyB,
                           exchanges: [exchangeA])
      ], modifyDate: Date())
      XCTAssertEqual(a, b)
   }

   func testHistoricalPriceIsEqual() {
      let a = HistoricalPrice(time: 147_000, open: 80.0, high: 90.0, low: 81.0,
                              close: 88.0, volumeFrom: 1000, volumeTo: 10000)
      let b = HistoricalPrice(time: 147_000, open: 80.0, high: 90.0, low: 81.0,
                              close: 88.0, volumeFrom: 1000, volumeTo: 10000)
      XCTAssertEqual(a, b)
   }

   func testHistoricalPriceIsNotEqualIfTimeIsDifferent() {
      let a = HistoricalPrice(time: 147_000, open: 80.0, high: 90.0, low: 81.0,
                              close: 88.0, volumeFrom: 1000, volumeTo: 10000)
      let b = HistoricalPrice(time: 147_001, open: 80.0, high: 90.0, low: 81.0,
                              close: 88.0, volumeFrom: 1000, volumeTo: 10000)
      XCTAssertNotEqual(a, b)
   }

   func testHistoricalPriceListIsEqual() {
      let currentDate = Date()
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let a = HistoricalPriceList(baseCurrency: currencyB,
                                  quoteCurrency: currencyA,
                                  exchange: exchangeA,
                                  historicalPrices:
                                  [
                                     HistoricalPrice(time: 147_000, open: 80.0, high: 90.0, low: 81.0,
                                                     close: 88.0, volumeFrom: 1000, volumeTo: 10000),
                                     HistoricalPrice(time: 147_001, open: 80.0, high: 90.0, low: 81.0,
                                                     close: 88.0, volumeFrom: 1000, volumeTo: 10000)
                                  ], modifyDate: currentDate)
      let b = HistoricalPriceList(baseCurrency: currencyB,
                                  quoteCurrency: currencyA,
                                  exchange: exchangeA,
                                  historicalPrices:
                                  [
                                     HistoricalPrice(time: 147_000, open: 80.0, high: 90.0, low: 81.0,
                                                     close: 88.0, volumeFrom: 1000, volumeTo: 10000),
                                     HistoricalPrice(time: 147_001, open: 80.0, high: 90.0, low: 81.0,
                                                     close: 88.0, volumeFrom: 1000, volumeTo: 10000)
                                  ], modifyDate: currentDate)
      XCTAssertEqual(a, b)
   }

   func testHistoricalPriceListIsNotEqualIfPriceAreDifferent() {
      let currentDate = Date()
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let a = HistoricalPriceList(baseCurrency: currencyB,
                                  quoteCurrency: currencyA,
                                  exchange: exchangeA,
                                  historicalPrices:
                                  [
                                     HistoricalPrice(time: 147_000, open: 80.0, high: 90.0, low: 81.0,
                                                     close: 88.0, volumeFrom: 1000, volumeTo: 10000),
                                     HistoricalPrice(time: 147_001, open: 80.0, high: 90.0, low: 81.0,
                                                     close: 88.0, volumeFrom: 1000, volumeTo: 10000)
                                  ], modifyDate: currentDate)
      let b = HistoricalPriceList(baseCurrency: currencyB,
                                  quoteCurrency: currencyA,
                                  exchange: exchangeA,
                                  historicalPrices:
                                  [
                                     HistoricalPrice(time: 147_002, open: 80.0, high: 90.0, low: 81.0,
                                                     close: 88.0, volumeFrom: 1000, volumeTo: 10000),
                                     HistoricalPrice(time: 147_001, open: 80.0, high: 90.0, low: 81.0,
                                                     close: 88.0, volumeFrom: 1000, volumeTo: 10000)
                                  ], modifyDate: currentDate)
      XCTAssertNotEqual(a, b)
   }

   func testStreamPriceIsEqual() {
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let a = StreamPrice(type: .current, exchange: exchangeA, baseCurrency: currencyB,
                          quoteCurrency: currencyA, priceChange: .down, price: 2000.0, bid: 123,
                          offer: 124, lastUpdateTimeStamp: 147_000, avg: 2000, lastVolume: 1000,
                          lastVolumeTo: 10000, lastTradeId: 88, volumeHour: 1000, volumeHourTo: 10000,
                          volume24h: 1000, volume24hTo: 10000, openHour: 123_132, highHour: 123_551,
                          lowHour: 123_555, open24Hour: 199, high24Hour: 2999, low24Hour: 1888,
                          lastMarket: 1222, mask: "ce64")
      let b = StreamPrice(type: .current, exchange: exchangeA, baseCurrency: currencyB,
                          quoteCurrency: currencyA, priceChange: .down, price: 2000.0, bid: 123,
                          offer: 124, lastUpdateTimeStamp: 147_000, avg: 2000, lastVolume: 1000,
                          lastVolumeTo: 10000, lastTradeId: 88, volumeHour: 1000, volumeHourTo: 10000,
                          volume24h: 1000, volume24hTo: 10000, openHour: 123_132, highHour: 123_551,
                          lowHour: 123_555, open24Hour: 199, high24Hour: 2999, low24Hour: 1888,
                          lastMarket: 1222, mask: "ce64")
      XCTAssertEqual(a, b)
   }

   func testStreamPriceIsNotEqualIfMaskIntIsDifferent() {
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let a = StreamPrice(type: .current, exchange: exchangeA, baseCurrency: currencyB,
                          quoteCurrency: currencyA, priceChange: .down, price: 2000.0, bid: 123,
                          offer: 124, lastUpdateTimeStamp: 147_000, avg: 2000, lastVolume: 1000,
                          lastVolumeTo: 10000, lastTradeId: 88, volumeHour: 1000, volumeHourTo: 10000,
                          volume24h: 1000, volume24hTo: 10000, openHour: 123_132, highHour: 123_551,
                          lowHour: 123_555, open24Hour: 199, high24Hour: 2999, low24Hour: 1888,
                          lastMarket: 1222, mask: "ce64")
      let b = StreamPrice(type: .current, exchange: exchangeA, baseCurrency: currencyB,
                          quoteCurrency: currencyA, priceChange: .down, price: 2000.0, bid: 123,
                          offer: 124, lastUpdateTimeStamp: 147_000, avg: 2000, lastVolume: 1000,
                          lastVolumeTo: 10000, lastTradeId: 88, volumeHour: 1000, volumeHourTo: 10000,
                          volume24h: 1000, volume24hTo: 10000, openHour: 123_132, highHour: 123_551,
                          lowHour: 123_555, open24Hour: 199, high24Hour: 2999, low24Hour: 1888,
                          lastMarket: 1222, mask: "ab12")
      XCTAssertNotEqual(a, b)
   }
}
