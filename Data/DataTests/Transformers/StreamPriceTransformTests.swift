//
//  StreamPriceTransformTests.swift
//  Data
//
//  Created by Hong on 16/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import XCTest

class StreamPriceTransformTests: XCTestCase {
   let streamPrice = StreamPrice(type: .current, exchange: Exchange(id: "Gemini", name: "Gemini"),
                                 baseCurrency: Currency(id: "BTC", name: "Bitcoin", symbol: "BTC"),
                                 quoteCurrency: Currency(id: "DASH", name: "Dash", symbol: "DASH"),
                                 priceChange: .down, price: 2000.0, bid: 123,
                                 offer: 124, lastUpdateTimeStamp: 147_000, avg: 2000, lastVolume: 1000,
                                 lastVolumeTo: 10000, lastTradeId: 88, volumeHour: 1000, volumeHourTo: 10000,
                                 volume24h: 1000, volume24hTo: 10000, openHour: 123_132, highHour: 123_551,
                                 lowHour: 123_555, open24Hour: 199, high24Hour: 2999, low24Hour: 1888,
                                 lastMarket: 1222, mask: "ce64")

   let streamPriceData = StreamPriceData(type: PriceStreamType.current.rawValue,
                                         exchange: "Gemini",
                                         baseCurrency: "BTC",
                                         quoteCurrency: "DASH",
                                         priceChange: PriceChange.down.rawValue,
                                         price: 2000.0, bid: 123, offer: 124, lastUpdateTimeStamp: 147_000,
                                         avg: 2000, lastVolume: 1000, lastVolumeTo: 10000, lastTradeId: 88,
                                         volumeHour: 1000, volumeHourTo: 10000, volume24h: 1000,
                                         volume24hTo: 10000, openHour: 123_132, highHour: 123_551,
                                         lowHour: 123_555, open24Hour: 199, high24Hour: 2999, low24Hour: 1888,
                                         lastMarket: 1222, mask: "ce64")

   func testSteamPriceAsData() {
      XCTAssertTrue(streamPrice.asData() == streamPriceData)
   }
}
