//
//  SortableTests.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

private class TestObject: Sortable {
   var modifyDate: Date = Date()
}

class SortableTests: XCTestCase {
   func testObjectsAreSortedByModifyDateAscending() {
      let first = TestObject()
      first.modifyDate = Date(timeIntervalSinceNow: -20)
      let second = TestObject()

      XCTAssertEqual([first, second].sorted(), [first, second])
      XCTAssertEqual([first, second].sorted(by: <), [first, second])
   }

   func testObjectsAreSortedByModifyDateDescending() {
      let first = TestObject()
      first.modifyDate = Date(timeIntervalSinceNow: -20)
      let second = TestObject()

      XCTAssertEqual([first, second].sorted(by: >), [second, first])
   }
}
