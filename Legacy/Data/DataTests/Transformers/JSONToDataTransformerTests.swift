//
//  JSONToDataTransformerTests.swift
//  Data
//
//  Created by Hong on 15/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import XCTest

class JSONToDataTransformerTests: XCTestCase {
   func testPriceListDataJSONFailed() {
      let json = ["aa": "e"]

      XCTAssertThrowsError(try CurrencyPairListData(json: json, id: "PriceList")) { error in
         guard case ParseError.parseFailed = error else {
            return XCTFail()
         }
      }
   }

   func testPriceListDataCountFailed() {
      let json = [String: String]()

      XCTAssertThrowsError(try CurrencyPairListData(json: json, id: "PriceList")) { error in
         guard case ParseError.parseFailed = error else {
            return XCTFail()
         }
      }
   }

   func testPriceListDataFromCurrencyNil() {
      let json: [[String: Any]] = [
         [
            "id": "",
            "quote": ["id": "ANT", "name": "Aragon", "symbol": "ANT"],
            "exchange": [["id": "Gemini", "name": "Gemini"]]
         ]
      ]

      let data = try! CurrencyPairListData(json: json, id: "bitpal-5118")

      XCTAssertTrue(data.currencyPairs.isEmpty)
   }

   func testPriceListDataToCurrencyNil() {
      let json: [[String: Any]] = [
         [
            "id": "",
            "base": ["id": "BTC", "name": "Bitcoin", "symbol": "BTC"],
            "exchange": [["id": "Gemini", "name": "Gemini"]]
         ]
      ]

      let data = try! CurrencyPairListData(json: json, id: "PriceList")

      XCTAssertTrue(data.currencyPairs.isEmpty)
   }

   func testPriceListDataFromCurrencyToCurrencySuccess() {
      let json: [[String: Any]] = [
         [
            "id": "BTC_ANT",
            "b": ["n": "Bitcoin"],
            "q": ["n": "Aragon"],
            "e": ["Gemini"]
         ]
      ]

      let data = try! CurrencyPairListData(json: json, id: "BTC_ANT")

      XCTAssertTrue(data.currencyPairs.count == 1)
      let expectedData = CurrencyPairListData(id: "BTC_ANT",
                                              currencyPairs: [
                                                 CurrencyPairGroupData(id: "BTC_ANT",
                                                                       baseCurrency: CurrencyData(id: "BTC",
                                                                                                  name: "Bitcoin",
                                                                                                  symbol: "BTC"),
                                                                       quoteCurrency: CurrencyData(id: "ANT",
                                                                                                   name: "Aragon",
                                                                                                   symbol: "ANT"),
                                                                       exchanges: [
                                                                          ExchangeData(id: "Gemini",
                                                                                       name: "Gemini")
                                                                       ])
                                              ],
                                              modifyDate: data.modifyDate)
      XCTAssertTrue(expectedData == data)
   }

   func testStreamPriceDataSeparatorFailed() {
      let json = "qq"

      XCTAssertThrowsError(try StreamPriceData(streamData: json)) { error in
         guard case ParseError.parseFailed = error else {
            return XCTFail()
         }
      }
   }

   func testStreamPriceDataParseFailed() {
      let json = "qwe~Gemini~USD~BTC~1~123.0~1~0.5~0.5~5~0.5~0.5~mask"

      XCTAssertThrowsError(try StreamPriceData(streamData: json)) { error in
         guard case ParseError.parseFailed = error else {
            return XCTFail()
         }
      }
   }

   func testStreamPriceDataEmpty() {
      let json = ""

      XCTAssertThrowsError(try StreamPriceData(streamData: json)) { error in
         guard case ParseError.parseFailed = error else {
            return XCTFail()
         }
      }
   }

   // TODO: lihao fix the parse stream price with a successful parse
   //   func testStreamPriceDataParseSuccess() {
//      let json = "0~Gemini~USD~BTC~1~123.0~1~0.5~0.5~5~0.5~0.5~mask"
//
//
//      let data = try! StreamPriceData(streamData: json)
//      let expecetedData = StreamPriceData(type: 0, exchange: "Gemini", baseCurrency: "USD", quoteCurrency: "BTC", priceChange: 1, price: 123.0, lastUpdateTimeStamp: 1, lastVolume: 0.5, lastVolumeTo: 0.5, lastTradeId: 5, volume24h: 0.5, volume24hTo: 0.5, maskInt: "mask")
//
//      XCTAssertTrue(data == expecetedData)
   //   }
}
