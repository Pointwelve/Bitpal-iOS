//
//  OrchestratedVolatileCacheTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class OrchestratedVolatileCacheTests: XCTestCase {
   var disposeBag: DisposeBag!

   override func setUp() {
      disposeBag = DisposeBag()
   }

   override func tearDown() {
      disposeBag = nil
   }
}

extension OrchestratedVolatileCacheTests {
   func testExpiryIsRespectedWhenValuesAreReadWithFactoryMethod() {
      let memory = MemoryCache<String, ModifiableItem>()
      let fauxDisk = MemoryCache<String, ModifiableItem>()
      let cache = CacheFactory.localOrchestratedVolatileCache(memory: memory, disk: fauxDisk, expiry: 3, maximumSize: 100)
      let expect1 = expectation(description: "Created")

      cache.set(.init(), for: "a")
         .map { _ -> String in
            sleep(2)
            expect1.fulfill()
            return ""
         }
         .subscribe().disposed(by: disposeBag)

      waitForExpectations(timeout: 3) { error in
         let expect2 = self.expectation(description: "StillExists")
         cache.get("a")
            .subscribe(onNext: { _ in
               sleep(2)
               expect2.fulfill()
            }).disposed(by: self.disposeBag)

         self.waitForExpectations(timeout: 3, handler: { error in
            let expect3 = self.expectation(description: "CeasesToExist")
            cache.get("a")
               .subscribe(onError: { _ in
                  expect3.fulfill()
               }).disposed(by: self.disposeBag)

            self.waitForExpectations(timeout: 1, handler: { error in
               print(String(describing: error))
               XCTAssertNil(error)
            })
         })
      }
   }

   func testExpiryIsRespectedWhenValuesAreRead() {
      let memory = MemoryCache<String, ModifiableItem>()
      let fauxDisk = MemoryCache<String, ModifiableItem>()
      let cache = OrchestratedVolatileCache(maximumSize: 100, expiry: 3, memory: memory, disk: fauxDisk)
      let expect1 = expectation(description: "Created")

      cache.set(.init(), for: "a")
         .map { _ -> String in
            sleep(2)
            expect1.fulfill()
            return ""
         }
         .subscribe().disposed(by: disposeBag)

      waitForExpectations(timeout: 3) { error in
         let expect2 = self.expectation(description: "StillExists")
         cache.get("a")
            .subscribe(onNext: { _ in
               sleep(2)
               expect2.fulfill()
            }).disposed(by: self.disposeBag)

         self.waitForExpectations(timeout: 3, handler: { error in
            let expect3 = self.expectation(description: "CeasesToExist")
            cache.get("a")
               .subscribe(onError: { _ in
                  expect3.fulfill()
               }).disposed(by: self.disposeBag)

            self.waitForExpectations(timeout: 1, handler: { error in
               print(String(describing: error))
               XCTAssertNil(error)
            })
         })
      }
   }

   func testMaximumLimitIsRespectedWhenValuesAreSetMultipleTimes() {
      let memory = MemoryCache<String, ModifiableItem>()
      let fauxDisk = MemoryCache<String, ModifiableItem>()
      let cache = OrchestratedVolatileCache(maximumSize: 2, expiry: 100, memory: memory, disk: fauxDisk)
      let expect = expectation(description: "Validated")

      cache.set(.init(), for: "a")
         .flatMap { _ in
            cache.set(.init(), for: "b")
         }
         .flatMap { _ in
            cache.set(.init(), for: "c")
         }
         .flatMap { _ in
            fauxDisk.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.set(.init(), for: "d")
         }
         .flatMap { _ in
            cache.set(.init(), for: "e")
         }
         .flatMap { _ in
            fauxDisk.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.set(.init(), for: "f")
         }
         .flatMap { _ in
            cache.set(.init(), for: "g")
         }
         .flatMap { _ in
            fauxDisk.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            expect.fulfill()
            return "test"
         }.subscribe().disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testMaximumLimitIsRespectedWhenValuesAreSetMultipleTimesByFactoryWithNetwork() {
      let memory = MemoryCache<String, ModifiableItem>()
      let fauxDisk = MemoryCache<String, ModifiableItem>()
      let cache = CacheFactory.orchestratedVolatileCache(memory: memory, disk: fauxDisk, network: SucceedingGetTestCache(), expiry: 100, maximumSize: 2)
      let expect = expectation(description: "Validated")

      cache.set(.init(), for: "a")
         .flatMap { _ in
            cache.set(.init(), for: "b")
         }
         .flatMap { _ in
            cache.set(.init(), for: "c")
         }
         .flatMap { _ in
            fauxDisk.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.set(.init(), for: "d")
         }
         .flatMap { _ in
            cache.set(.init(), for: "e")
         }
         .flatMap { _ in
            fauxDisk.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.set(.init(), for: "f")
         }
         .flatMap { _ in
            cache.set(.init(), for: "g")
         }
         .flatMap { _ in
            fauxDisk.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            return "test"
         }
         .flatMap { _ in
            cache.keyValues()
         }
         .map { (items) -> String in
            XCTAssertEqual(items.count, 2)
            expect.fulfill()
            return "test"
         }.subscribe().disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}

// MARK: - Helpers

private class ModifiableItem: Modifiable {
   var modifyDate: Date = Date()
}

private class FailingGetTestCache: FailingCache<String, ModifiableItem> {
   var error: CacheError = .notFound

   override func get(_ key: String) -> Observable<ModifiableItem> {
      return Observable.error(error)
   }

   fileprivate override func set(_ value: ModifiableItem, for key: String) -> Observable<Void> {
      return Observable.just(())
   }
}

private class SucceedingGetTestCache: FailingCache<String, ModifiableItem> {
   var value: String = "test"

   override func get(_ key: String) -> Observable<ModifiableItem> {
      return Observable.just(ModifiableItem())
   }

   fileprivate override func set(_ value: ModifiableItem, for key: String) -> Observable<Void> {
      return Observable.just(())
   }
}

private class SucceedingSetTestCache: FailingCache<String, ModifiableItem> {
   var value = ModifiableItem()

   fileprivate override func set(_ value: ModifiableItem, for key: String) -> Observable<Void> {
      self.value = value
      return Observable.just(())
   }
}

private class SucceedingDeleteTestCache: FailingCache<String, ModifiableItem> {
   var deleted = false

   fileprivate override func delete(_ key: String) -> Observable<Void> {
      deleted = true
      return Observable.just(())
   }
}

private class SucceedingKeyValuesTestCache: FailingCache<String, ModifiableItem> {
   var key: String = "key"

   fileprivate override func keyValues() -> Observable<[(String, ModifiableItem)]> {
      return Observable.just([(key, ModifiableItem())])
   }
}
