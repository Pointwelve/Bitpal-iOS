//
//  ConfigurationPlistStorageTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import XCTest

class ConfigurationPlistStorageTests: XCTestCase {
   func testErrorIsThrownIfConfigurationFileIsMissing() {
      do {
         _ = try ConfigurationPlistStorage(file: "MissingFile", ofType: "Any", inBundle: Bundle(for: ConfigurationPlistStorageTests.self))
         XCTFail("Initialization expected to fail")
      } catch {
         switch error {
         case FileError.missing:
            XCTAssertTrue(true)
         default:
            XCTFail("Unexpected error occurred")
         }
      }
   }
}
