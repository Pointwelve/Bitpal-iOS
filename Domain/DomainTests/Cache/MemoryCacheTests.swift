//
//  MemoryCacheTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class MemoryCacheTests: XCTestCase {
   var disposeBag: DisposeBag!

   override func setUp() {
      disposeBag = DisposeBag()
   }

   override func tearDown() {
      disposeBag = nil
   }
}

extension MemoryCacheTests {
   func testMemoryCacheTestPersists() {
      let cache = MemoryCache<String, String>()
      let expect = expectation(description: "Set Complete")

      cache.set("test", for: "test")
         .flatMap { _ in cache.get("test") }
         .subscribe(onNext: { value in
            XCTAssertEqual(value, "test")
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testMemoryCacheDeleteNoLongerPersistsValue() {
      let cache = MemoryCache<String, String>()
      let expect = expectation(description: "Delete Complete")

      cache.set("test", for: "test")
         .flatMap { _ in cache.delete("test") }
         .subscribe(onNext: { _ in
            cache.get("test")
               .catchErrorJustReturn("deleted")
               .subscribe(onNext: { value in
                  XCTAssertEqual(value, "deleted")
                  expect.fulfill()
               }).disposed(by: self.disposeBag)
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testMemoryCacheClear() {
      let cache = MemoryCache<String, String>()
      let expect = expectation(description: "Clear Complete")
      cache.set("test", for: "test")
         .subscribe(onNext: { _ in
            cache.clear()
            cache.keyValues().subscribe(onNext: { items in
               XCTAssertEqual(items.count, 0)
               expect.fulfill()
            }).disposed(by: self.disposeBag)
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testMemoryCacheKeyValues() {
      let cache = MemoryCache<String, String>()
      let expect = expectation(description: "KeyValues Complete")
      cache.set("test", for: "test")
         .subscribe(onNext: { _ in
            cache.keyValues().subscribe(onNext: { items in
               XCTAssertEqual(items.count, 1)
               expect.fulfill()
            }).disposed(by: self.disposeBag)
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}
