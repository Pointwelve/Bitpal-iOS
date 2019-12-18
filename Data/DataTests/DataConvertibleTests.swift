//
//  DataConvertibleTests.swift
//  Data
//
//  Created by Alvin Choo on 25/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import XCTest

class DataConvertibleTests: XCTestCase {
   func testDataConvertible() {
      let testData = TestableDataConvertibleObject(test: "test")

      let expectedData = TestableDataConvertedObject(test: "test")
      let convertedData = testData.asData()

      XCTAssertTrue(expectedData == convertedData)
   }

   func testDataConvertibleList() {
      let testData = [TestableDataConvertibleObject(test: "test")]
      let convertedData = testData.asData()
      let expectedData = [TestableDataConvertedObject(test: "test")]

      XCTAssertTrue(expectedData == convertedData)
   }
}
