//
//  PreferencesUserDefaultsStroageTests.swift
//  Data
//
//  Created by Alvin Choo on 25/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RxSwift
import XCTest

class PreferencesUserDefaultsStroageTests: XCTestCase {
   private let disposeBag = DisposeBag()

   override func setUp() {
      if let domain = Bundle.main.bundleIdentifier {
         UserDefaults.standard.removePersistentDomain(forName: domain)
      }
   }

   func testGetFailed() {
      let userDefaults = PreferencesUserDefaultsStorage()
      let expect = expectation(description: "executed")
      userDefaults.get("WrongKey").subscribe(onError: { error in
         switch error {
         case ParseError.parseFailed:
            XCTAssertTrue(true)
         default:
            XCTFail()
         }

         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testSet() {
      let userDefaults = PreferencesUserDefaultsStorage()
      let expect = expectation(description: "executed")
      let language = try! LanguageData(code: "en")
      let data = PreferencesData(language: language,
                                 theme: try! ThemeData(name: "dark"),
                                 databaseName: "test",
                                 installed: true,
                                 chartType: 0)

      userDefaults.set(data, for: "test").subscribe(onNext: {
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testGetSet() {
      let userDefaults = PreferencesUserDefaultsStorage()
      let expect = expectation(description: "executed")
      let language = try! LanguageData(code: "en")
      let data = PreferencesData(language: language,
                                 theme: try! ThemeData(name: "dark"),
                                 databaseName: "test",
                                 installed: true,
                                 chartType: 0)

      userDefaults.set(data, for: "test").subscribe(onNext: {}).disposed(by: disposeBag)

      userDefaults.get("test").subscribe(onNext: { callBackData in
         XCTAssertTrue(callBackData == data)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.5) { error in
         XCTAssertNil(error)
      }
   }
}
