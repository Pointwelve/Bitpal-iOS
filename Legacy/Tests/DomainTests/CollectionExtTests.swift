//
//  CollectionExtTests.swift
//  Domain
//
//  Created by Kok Hong Choo on 28/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class CollectionExtTests: XCTestCase {
   func testOptionalCollection() {
      let data = [1, 2, 3]

      XCTAssertNil(data[safe: 5])
      XCTAssertNotNil(data[safe: 1])
      XCTAssertEqual(data[safe: 1], 2)
   }
}
