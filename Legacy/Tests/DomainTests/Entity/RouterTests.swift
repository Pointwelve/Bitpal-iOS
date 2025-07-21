//
//  RouterTests.swift
//  Domain
//
//  Created by Ryne Cheow on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import XCTest

enum TestRouter: APIRouter {
   case test
   var relativePath: String {
      return "/get"
   }

   var method: HTTPMethodType {
      return .get
   }
}

class RouterTests: XCTestCase {
   func testBaseRouter() {
      // Basic router with extension methods not overriden
      XCTAssertTrue(TestRouter.test.relativePath == "/get")
      XCTAssertTrue(TestRouter.test.method == .get)
      XCTAssertTrue(TestRouter.test.parameters == nil)
      XCTAssertTrue(TestRouter.test.query == nil)
   }

   func testPriceRouter() {
      XCTAssertTrue(PriceRouter
         .getPriceList(["BTC", "ETH"], ["USD"], "Gemini")
         .relativePath == "/data/pricemulti")
      XCTAssertTrue(PriceRouter
         .getHistoricalPriceList(.day, "BTC", "USD", "Gemini", 6, 120)
         .relativePath == "/data/histoday")
      XCTAssertTrue(PriceRouter
         .getHistoricalPriceList(.minute, "BTC", "USD", "Gemini", 6, 120)
         .relativePath == "/data/histominute")
      XCTAssertTrue(PriceRouter
         .getHistoricalPriceList(.hour, "BTC", "USD", "Gemini", 6, 120)
         .relativePath == "/data/histohour")
      XCTAssertTrue(PriceRouter
         .getHistoricalPriceList(.day, "BTC", "USD", "Gemini", 6, 120)
         .method == .get)
      XCTAssertTrue(PriceRouter
         .getHistoricalPriceList(.minute, "BTC", "USD", "Gemini", 6, 120)
         .method == .get)
      XCTAssertTrue(PriceRouter
         .getHistoricalPriceList(.hour, "BTC", "USD", "Gemini", 6, 120)
         .method == .get)
      XCTAssertTrue(PriceRouter
         .getPriceList(["BTC", "ETH"], ["USD"], "Gemini")
         .query != nil)
      XCTAssertFalse(PriceRouter
         .getHistoricalPriceList(.day, "BTC", "USD", "Gemini", 6, 120)
         .query == nil)
   }

   func testSocketRouter() {
      XCTAssertTrue(PriceSocketRouter
         .price(subscriptions: [])
         .parameters != nil)
   }

   func testFirebaseRouter() {
      XCTAssertNil(FirebaseRouter.read([]).parameters)
   }

   func testPushNotificationRouter() {
      XCTAssertTrue(PushNotificationRouter
         .register("")
         .relativePath == "/api/push/register")

      XCTAssertTrue(PushNotificationRouter
         .register("")
         .method == .post)

      let expectedDict: NSDictionary = ["token": "abc"]
      let currentDict = NSDictionary(dictionary: PushNotificationRouter
         .register("abc").parameters!)

      XCTAssertEqual(expectedDict, currentDict)

      XCTAssertTrue(PushNotificationRouter
         .register("abc")
         .authenticatable)
   }

   func testCurrenciesRouter() {
      XCTAssertTrue(CurrenciesRouter
         .currencies
         .relativePath == "/api/v2/currencies")

      XCTAssertTrue(CurrenciesRouter
         .currencies
         .method == .get)
   }

   func testAuthenticationRouter() {
      XCTAssertTrue(AuthenticationRouter
         .authenticate(identifier: "abc")
         .relativePath == "/api/auth")

      XCTAssertTrue(AuthenticationRouter
         .authenticate(identifier: "abc")
         .method == .post)

      let expectedDict: NSDictionary = ["identifier": "abc"]
      let currentDict = NSDictionary(dictionary: AuthenticationRouter
         .authenticate(identifier: "abc").parameters!)

      XCTAssertEqual(expectedDict, currentDict)
   }
}
