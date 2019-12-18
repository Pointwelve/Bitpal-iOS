//
//  StringExtTests.swift
//  App
//
//  Created by Alvin Choo on 23/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import XCTest

class StringExtTests: XCTestCase {
   func testAttributedStringLetterSpacing() {
      let testString = "ABC".attributedString(withLetterSpacing: 0.0)
      var range = NSRange(location: 0, length: "ABC".count)
      let value = testString.attributes(at: 0, effectiveRange: &range)
      guard let letterSpacing = value[.kern] as? CGFloat else {
         XCTFail()
         return
      }

      XCTAssertTrue(letterSpacing == 0)
   }

   func testAttributedStringLineHeight() {
      let testString = "ABC".attributedString(lineHeight: 0.0)
      var range = NSRange(location: 0, length: "ABC".count)
      let value = testString.attributes(at: 0, effectiveRange: &range)
      guard let lineHeight = value[.paragraphStyle] as? NSParagraphStyle else {
         XCTFail()
         return
      }

      XCTAssertTrue(lineHeight.minimumLineHeight == 0)
   }

   func testAttributedStringTextAlignment() {
      let testString = "ABC".attributedString(textAlignment: .center)
      var range = NSRange(location: 0, length: "ABC".count)
      let value = testString.attributes(at: 0, effectiveRange: &range)
      guard let textAlignment = value[.paragraphStyle] as? NSParagraphStyle else {
         XCTFail()
         return
      }

      XCTAssertTrue(textAlignment.alignment == NSTextAlignment.center)
   }

   func testAttributedStringTextColor() {
      let testString = "ABC".attributedString(textColor: UIColor.blue)
      var range = NSRange(location: 0, length: "ABC".count)
      let value = testString.attributes(at: 0, effectiveRange: &range)
      guard let textColor = value[.foregroundColor] as? UIColor else {
         XCTFail()
         return
      }

      XCTAssertTrue(textColor == .blue)
   }
}
