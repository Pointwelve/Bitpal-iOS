//
//  AuthenticationTokenTests.swift
//  DomainTests
//
//  Created by Ryne Cheow on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class AuthenticationTokenTests: XCTestCase {
   func testTokenIsEqual() {
      let a = AuthenticationToken(token: "abc")
      let b = AuthenticationToken(token: "abc")
      XCTAssertEqual(a, b)
   }

   func testTokenIsNotEqual() {
      let a = AuthenticationToken(token: "abc")
      let b = AuthenticationToken(token: "def")
      XCTAssertNotEqual(a, b)
   }
}
