//
//  RouteProviderTests.swift
//  AppTests
//
//  Created by Li Hao Lai on 29/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Bitpal
import Foundation
import RxCocoa
import XCTest

class RouteProviderTests: XCTestCase {
   func testDeeplinks() {
      XCTAssertNotNil(RouteProvider.open(with: "bitpal://watchlist"))
      XCTAssertNotNil(RouteProvider.open(with: "bitpal://watchlist/add"))
      XCTAssertNotNil(RouteProvider.open(with: "bitpal://watchlist/Gemini/BTC_USD"))
      XCTAssertNotNil(RouteProvider.open(with: "bitpal://alerts"))
      XCTAssertNotNil(RouteProvider.open(with: "bitpal://settings/terms"))

      XCTAssertNil(RouteProvider.open(with: "bitpal://NOT_EXIST"))
   }
}
