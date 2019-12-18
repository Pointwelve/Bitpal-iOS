//
//  CacheTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class CacheTests: XCTestCase {
   var disposeBag: DisposeBag!

   override func setUp() {
      disposeBag = DisposeBag()
   }

   override func tearDown() {
      disposeBag = nil
   }
}

// MARK: - Key Values

extension CacheTests {
   func testCacheCompositionKeyValuesCascadesOnError() {
      let parent = FailingCache<String, String>()
      let child = SucceedingKeyValuesTestCache()
      let expect = expectation(description: "Delegation")

      parent.compose(child).keyValues().subscribe(onNext: { items in
         XCTAssertEqual(items.first?.0, "key")
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testCacheCompositionKeyValuesDoesNotCascades() {
      let parent = SucceedingKeyValuesTestCache()
      let child = SucceedingKeyValuesTestCache()
      child.key = "key2"
      let expect = expectation(description: "Delegation")

      parent.compose(child).keyValues().subscribe(onNext: { items in
         XCTAssertEqual(items.first?.0, "key")
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}

// MARK: - Delete

extension CacheTests {
   func testCacheCompositionDeleteCascades() {
      let greatGrandParent = SucceedingDeleteTestCache()
      let grandParent = SucceedingDeleteTestCache()
      let parent = SucceedingDeleteTestCache()
      let child = SucceedingDeleteTestCache()
      let combined = greatGrandParent.compose(grandParent).compose(parent).compose(child)
      let expect = expectation(description: "Delegation")

      combined.delete("test")
         .subscribe(onNext: { _ in
            XCTAssertTrue(greatGrandParent.deleted)
            XCTAssertTrue(grandParent.deleted)
            XCTAssertTrue(parent.deleted)
            XCTAssertTrue(child.deleted)
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testCacheCompositionDeleteStopCascadingOnError() {
      let greatGrandParent = SucceedingDeleteTestCache()
      let grandParent = SucceedingDeleteTestCache()
      let parent = FailingCache<String, String>()
      let child = SucceedingDeleteTestCache()
      let combined = greatGrandParent.compose(grandParent).compose(parent).compose(child)
      let expect = expectation(description: "Delegation")

      combined.delete("test")
         .subscribe(onError: { error in
            XCTAssertEqual(error as! CacheError, .invalid)
            XCTAssertTrue(greatGrandParent.deleted)
            XCTAssertTrue(grandParent.deleted)
            XCTAssertFalse(child.deleted)
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}

// MARK: - Set

extension CacheTests {
   func testCacheCompositionSetStopsCascadingOnError() {
      let greatGrandParent = SucceedingSetTestCache()
      let grandParent = SucceedingSetTestCache()
      let parent = FailingCache<String, String>()
      let child = SucceedingSetTestCache()
      let combined = greatGrandParent.compose(grandParent).compose(parent).compose(child)
      let expect = expectation(description: "Delegation")

      combined.set("test", for: "test")
         .subscribe(onError: { error in
            XCTAssertEqual(error as! CacheError, .invalid)
            XCTAssertEqual(greatGrandParent.value, "test")
            XCTAssertEqual(grandParent.value, "test")
            XCTAssertTrue(child.value.isEmpty)
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testCacheCompositionSetCascades() {
      let greatGrandParent = SucceedingSetTestCache()
      let grandParent = SucceedingSetTestCache()
      let parent = SucceedingSetTestCache()
      let child = SucceedingSetTestCache()
      let combined = greatGrandParent.compose(grandParent).compose(parent).compose(child)
      let expect = expectation(description: "Delegation")

      combined.set("test", for: "test")
         .subscribe(onNext: { _ in
            XCTAssertEqual(greatGrandParent.value, "test")
            XCTAssertEqual(grandParent.value, "test")
            XCTAssertEqual(parent.value, "test")
            XCTAssertEqual(child.value, "test")
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}

// MARK: - Get

extension CacheTests {
   func testCacheCompositionGetDelegatesWhenNotFoundInPrimaryCache() {
      let greatGrandParent = FailingGetTestCache()
      let grandParent = FailingGetTestCache()
      let parent = FailingGetTestCache()
      let child = SucceedingGetTestCache()
      let expect = expectation(description: "Delegation")
      let combined = greatGrandParent + grandParent + parent + child

      combined.get("test").subscribe(onNext: { value in
         XCTAssertEqual("test", value)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testCacheCompositionGetDelegatesFailsWhenNotFoundInAllCaches() {
      let grandparent = FailingGetTestCache()
      let parent = FailingGetTestCache()
      let child = FailingGetTestCache()
      let expect = expectation(description: "Delegation")

      child.error = CacheError.expired

      grandparent
         .compose(parent)
         .compose(child)
         .get("test")
         .catchError { (error) -> Observable<String> in
            XCTAssertTrue(CacheError.expired == error as! CacheError)
            expect.fulfill()
            return Observable.just("")
         }.subscribe().disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testCacheCompositionGetStopsDelegatingWhenFound() {
      let grandparent = FailingGetTestCache()
      let parent = SucceedingGetTestCache()
      let child = FailingGetTestCache()
      let expect = expectation(description: "Delegation")

      child.error = CacheError.expired

      grandparent
         .compose(parent)
         .compose(child)
         .get("test")
         .subscribe(onNext: { value in
            XCTAssertEqual("test", value)
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}

// MARK: - Helpers

private class FailingGetTestCache: FailingCache<String, String> {
   var error: CacheError = .notFound

   override func get(_ key: String) -> Observable<String> {
      return Observable.error(error)
   }

   fileprivate override func set(_ value: String, for key: String) -> Observable<Void> {
      return Observable.just(())
   }
}

private class SucceedingGetTestCache: FailingCache<String, String> {
   var value: String = "test"

   override func get(_ key: String) -> Observable<String> {
      return Observable.just(value)
   }

   fileprivate override func set(_ value: String, for key: String) -> Observable<Void> {
      return Observable.just(())
   }
}

private class SucceedingSetTestCache: FailingCache<String, String> {
   var value: String = ""

   fileprivate override func set(_ value: String, for key: String) -> Observable<Void> {
      self.value = value
      return Observable.just(())
   }
}

private class SucceedingDeleteTestCache: FailingCache<String, String> {
   var deleted = false

   fileprivate override func delete(_ key: String) -> Observable<Void> {
      deleted = true
      return Observable.just(())
   }
}

private class SucceedingKeyValuesTestCache: FailingCache<String, String> {
   var key: String = "key"

   fileprivate override func keyValues() -> Observable<[(String, String)]> {
      return Observable.just([(key, "test")])
   }
}
