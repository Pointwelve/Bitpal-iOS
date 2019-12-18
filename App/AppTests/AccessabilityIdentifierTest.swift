//
//  AccessabilityIdentifierTest.swift
//  App
//
//  Created by Alvin Choo on 23/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import XCTest

class AccessabilityIdentifierTest: XCTestCase {
   func testRawValueAccessabilityIndentifier() {
      let identifier = AccessibilityIdentifier.loadStateErrorViewMessage

      let testView = UIView(frame: CGRect.zero)
      testView.setAccessibility(id: identifier)

      XCTAssertTrue(testView.accessibilityIdentifier == identifier.rawValue)
   }
}
