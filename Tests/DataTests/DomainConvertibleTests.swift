//
//  DomainConvertibleTests.swift
//  Data
//
//  Created by Alvin Choo on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import XCTest

class DomainConvertibleTests: XCTestCase {
   func testDomainConvertible() {
      let testData = TestableDomainConvertibleObject(test: "test")

      let expectedData = TestableDomainConvertedObject(test: "test")
      let convertedData = testData.asDomain()

      XCTAssertTrue(expectedData == convertedData)
   }

   func testDomainConvertibleList() {
      let testData = [TestableDomainConvertibleObject(test: "test")]
      let convertedData = testData.asDomain()
      let expectedData = [TestableDomainConvertedObject(test: "test")]

      XCTAssertTrue(expectedData == convertedData)
   }
}
