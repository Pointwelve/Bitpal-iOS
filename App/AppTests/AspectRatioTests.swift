//
//  AspectRatioTests.swift
//  App
//
//  Created by Alvin Choo on 24/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import XCTest

class AspectRatioTests: XCTestCase {
   func testAspectRatioWidth() {
      let sample = AspectRatio(x: 3.0, y: 2.0)

      XCTAssertTrue(sample.widthMultiplier == 2.0 / 3.0)
   }

   func testAspectRatioHeight() {
      let sample = AspectRatio(x: 3.0, y: 2.0)

      XCTAssertTrue(sample.heightMultiplier == 3.0 / 2.0)
   }
}
