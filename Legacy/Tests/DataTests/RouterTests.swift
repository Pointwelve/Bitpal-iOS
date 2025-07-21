//
//  RouterTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import Foundation
import XCTest

enum TestRouter: Router {
   var parameters: [String: Any]? {
      return nil
   }

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
   }
}
