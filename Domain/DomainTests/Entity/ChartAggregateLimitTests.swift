//
//  ChartAggregateLimitTests.swift
//  DomainTests
//
//  Created by Kok Hong Choo on 1/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class ChartAggregateLimitTests: XCTestCase {
   func testChartAggregateMinuteValue() {
      XCTAssertEqual(ChartAggregateMinute.one.rawValue, 1)
      XCTAssertEqual(ChartAggregateMinute.five.rawValue, 5)
      XCTAssertEqual(ChartAggregateMinute.fifteen.rawValue, 15)
      XCTAssertEqual(ChartAggregateMinute.thirty.rawValue, 30)
      XCTAssertEqual(ChartAggregateMinute.sixty.rawValue, 60)
   }

   func testChartLimitHourValue() {
      XCTAssertEqual(ChartLimitHour.twentyFour.rawValue, 24)
      XCTAssertEqual(ChartLimitHour.twelve.rawValue, 12)
      XCTAssertEqual(ChartLimitHour.eight.rawValue, 8)
      XCTAssertEqual(ChartLimitHour.four.rawValue, 4)
      XCTAssertEqual(ChartLimitHour.one.rawValue, 1)
   }

   func testMinutePerHour() {
      XCTAssertEqual(ChartAggregateMinute.sixty.minutePerHour, 1)
   }

   func testLimitHour() {
      XCTAssertEqual(ChartAggregateMinute.sixty.limitHour(limit: .one), 1)
   }
}
