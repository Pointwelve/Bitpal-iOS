//
//  ThemeTests.swift
//  DomainTests
//
//  Created by Kok Hong Choo on 1/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import XCTest

class ThemeTests: XCTestCase {
   func testAnalayticsMedata() {
      let darkTheme = Theme.dark
      let expectedDarkDict: NSDictionary = ["Theme": "Dark"]
      let currentDarkDict = NSDictionary(dictionary: darkTheme.analyticsMetadata)

      XCTAssertEqual(expectedDarkDict, currentDarkDict)
      let lightTheme = Theme.light
      let expectedLightDict: NSDictionary = ["Theme": "Light"]
      let currentLightDict = NSDictionary(dictionary: lightTheme.analyticsMetadata)

      XCTAssertEqual(expectedLightDict, currentLightDict)

      XCTAssertTrue(Theme.default == Theme.dark)

      XCTAssertTrue(Theme(name: "qeqweqwe") == Theme.dark)

      XCTAssertTrue(Theme(name: "dark") == Theme.dark)
      XCTAssertTrue(Theme(name: "light") == Theme.light)
   }
}
