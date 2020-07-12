//
//  ErrorsTest.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import XCTest

class NSErrorTests: XCTestCase {
   func testIsNetworkUnreachableError() {
      let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
      XCTAssert(error.isNetworkUnreachableError)
   }

   func testIsNetworkTimeoutError() {
      let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
      XCTAssert(error.isNetworkTimeoutError)
   }

   func testErrorConstruction() {
      let error = NSError.with("Test error")

      guard let errorDescription = error.userInfo[NSLocalizedDescriptionKey] as? String else {
         XCTFail()
         return
      }
      XCTAssertEqual(errorDescription, "Test error")
   }
}
