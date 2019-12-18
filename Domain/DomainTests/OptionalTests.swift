//
//  OptionalTests.swift
//  Domain
//
//  Created by Ryne Cheow on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import XCTest

class OptionalTests: XCTestCase {
   func testOptionalStringIsNotEmpty() {
      // String conforms to protocol 'Emptyable'
      let a: String? = "a"
      XCTAssertFalse(a.isEmpty)
   }

   func testOptionalStringIsEmpty() {
      // String conforms to protocol 'Emptyable'
      let a: String? = nil
      XCTAssertTrue(a.isEmpty)
   }
}
