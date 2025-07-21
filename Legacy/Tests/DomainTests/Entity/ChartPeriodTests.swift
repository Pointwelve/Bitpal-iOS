//
//  ChartPeriodTests.swift
//  Domain
//
//  Created by Kok Hong Choo on 28/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import XCTest

class ChartPeriodTests: XCTestCase {
   func testChartPeriodOneMinuteEqual() {
      let oneMinute = ChartPeriod.oneMinute

      XCTAssertEqual(oneMinute.request.0, 1)
      XCTAssertEqual(oneMinute.request.1, .minute)
      XCTAssertEqual(oneMinute.limit, 60)
   }

   func testChartPeriodFiveMinuteEqual() {
      let fiveMinute = ChartPeriod.fiveMinute

      XCTAssertEqual(fiveMinute.request.0, 5)
      XCTAssertEqual(fiveMinute.request.1, .minute)
      XCTAssertEqual(fiveMinute.limit, 60)
   }

   func testChartPeriodFifteenMinuteEqual() {
      let fifteenMinutes = ChartPeriod.fifteenMinutes

      XCTAssertEqual(fifteenMinutes.request.0, 15)
      XCTAssertEqual(fifteenMinutes.request.1, .minute)
      XCTAssertEqual(fifteenMinutes.limit, 60)
   }

   func testChartPeriodOneHourEqual() {
      let oneHour = ChartPeriod.oneHour

      XCTAssertEqual(oneHour.request.0, 1)
      XCTAssertEqual(oneHour.request.1, .hour)
      XCTAssertEqual(oneHour.limit, 60)
   }

   func testChartPeriodFourHourEqual() {
      let fourHours = ChartPeriod.fourHours

      XCTAssertEqual(fourHours.request.0, 4)
      XCTAssertEqual(fourHours.request.1, .hour)
      XCTAssertEqual(fourHours.limit, 60)
   }

   func testChartPeriodOneDayEqual() {
      let oneDay = ChartPeriod.oneDay

      XCTAssertEqual(oneDay.request.0, 1)
      XCTAssertEqual(oneDay.request.1, .day)
      XCTAssertEqual(oneDay.limit, 60)
   }

   func testDayHistoPriceRequest() {
      let request = ChartPeriod.oneDay.historicalRequest(from: Currency(id: "NEO", name: "NEO", symbol: "NEO"),
                                                         toCurrency: Currency(id: "BTC", name: "Bitcoin", symbol: "BTC"),
                                                         exchange: Exchange(id: "Gemini", name: "Gemini"))

      let expectedRequest = HistoricalPriceListRequest(fromSymbol: Currency(id: "NEO", name: "NEO", symbol: "NEO"),
                                                       toSymbol: Currency(id: "BTC", name: "Bitcoin", symbol: "BTC"),
                                                       exchange: Exchange(id: "Gemini", name: "Gemini"),
                                                       aggregate: 1,
                                                       limit: 60,
                                                       routerType: .day)

      XCTAssertEqual(request, expectedRequest)
   }
}
