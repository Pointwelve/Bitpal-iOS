//
//  LayoutConstraintExt-Test.swift
//  App
//
//  Created by Alvin Choo on 23/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import XCTest

class LayoutConstraintExt_Test: XCTestCase {
   func testPriority() {
      let constraint = NSLayoutConstraint().constraint(withPriority: .required)
      XCTAssertTrue(constraint.priority == .required)
   }
}
