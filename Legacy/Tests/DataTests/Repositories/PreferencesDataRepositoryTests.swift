//
//  PreferencesDataRepositoryTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RxSwift
import XCTest

private class TestablePreferencesStorage: PreferencesStorage {
   override func get(_: String) -> Observable<PreferencesData> {
      return Observable.just(Preferences(language: Language.en).asData())
   }

   override func set(_ value: PreferencesData, for key: String) -> Observable<Void> {
      return Observable.just(())
   }
}

class PreferencesRepositoryTests: XCTestCase {
   func testPreferencesRepositoryReadResultsInError() {
      let storage = PreferencesStorage()
      let repository = PreferencesRepository(storage: storage)
      let read = repository.read()
      let expect = expectation(description: "error")
      let disposeBag = DisposeBag()
      read.subscribe(onNext: { _ in
         XCTFail()
      }, onError: { error in
         switch error {
         case CacheError.invalid:
            expect.fulfill()
         default:
            XCTFail()
         }
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testPreferencesRepositoryReadResultsInObject() {
      let storage = TestablePreferencesStorage()
      let repository = PreferencesRepository(storage: storage)
      let read = repository.read()
      let expect = expectation(description: "object")
      let disposeBag = DisposeBag()
      read.subscribe(onNext: { _ in
         expect.fulfill()
      }, onError: { _ in
         XCTFail()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testPreferencesRepositoryWriteResultsInError() {
      let storage = PreferencesStorage()
      let repository = PreferencesRepository(storage: storage)
      let read = repository.write(Preferences(language: Language.en))
      let expect = expectation(description: "error")
      let disposeBag = DisposeBag()
      read.subscribe(onNext: { _ in
         XCTFail()
      }, onError: { error in
         switch error {
         case CacheError.invalid:
            expect.fulfill()
         default:
            XCTFail()
         }
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testPreferencesRepositoryWriteResultsInObject() {
      let storage = TestablePreferencesStorage()
      let repository = PreferencesRepository(storage: storage)
      let read = repository.write(Preferences(language: Language.en))
      let expect = expectation(description: "object")
      let disposeBag = DisposeBag()
      read.subscribe(onNext: { _ in
         expect.fulfill()
      }, onError: { _ in
         XCTFail()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}
