//
//  ReloadTriggerTests.swift
//  App
//
//  Created by Alvin Choo on 23/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import RxCocoa
import RxSwift
import XCTest

class ReloadTriggerTests: XCTestCase {
   private let disposeBag = DisposeBag()

   func testForegroundTrigger() {
      let expect = expectation(description: "execution")

      let foregroundTriggerDriver = Observable.just(false).asDriver(onErrorJustReturn: false)

      let foregroundReloadTrigger = ReloadTrigger.inForeground(foregroundTriggerDriver)

      foregroundReloadTrigger.foregroundTrigger?.drive(onNext: { value in
         XCTAssertTrue(value == false)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testVisibleTrigger() {
      let expect = expectation(description: "execution")

      let visibleTriggerDriver = Observable.just(false).asDriver(onErrorJustReturn: false)

      let visibleReloadTrigger = ReloadTrigger.willBecomeVisible(visibleTriggerDriver)

      visibleReloadTrigger.visibleTrigger?.drive(onNext: { value in
         XCTAssertTrue(value == false)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testStaleTrigger() {
      let expect = expectation(description: "execution")

      let staleTriggerDriver = Observable.just(false).asDriver(onErrorJustReturn: false)

      let staleReloadTrigger = ReloadTrigger.becameStale(staleTriggerDriver)

      staleReloadTrigger.value.drive(onNext: { value in
         XCTAssertTrue(value == false)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testReachabilityTrigger() {
      let expect = expectation(description: "execution")

      let reachableTriggerDriver = Observable.just(false).asDriver(onErrorJustReturn: false)

      let reachableReloadTrigger = ReloadTrigger.becameReachable(reachableTriggerDriver)

      reachableReloadTrigger.reachabilityTrigger?.drive(onNext: { value in
         XCTAssertTrue(value == false)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testInForegroundTrigger() {
      let expect = expectation(description: "execution")

      let inForegroundTriggerDriver = Observable.just(false).asDriver(onErrorJustReturn: false)

      let inForegroundReloadTrigger = ReloadTrigger.inForeground(inForegroundTriggerDriver)

      inForegroundReloadTrigger.foregroundTrigger?.drive(onNext: { value in
         XCTAssertTrue(value == false)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testReloadTriggerArray() {
      let expect = expectation(description: "execution")

      let genericTrueDriver = Observable.just(true).asDriver(onErrorJustReturn: true)

      let inForegroundTriggerDriver = ReloadTrigger.inForeground(genericTrueDriver)
      let reachableTriggerDriver = ReloadTrigger.becameReachable(genericTrueDriver)
      let staleTriggerDriver = ReloadTrigger.becameStale(genericTrueDriver)
      let visibleTriggerDriver = ReloadTrigger.willBecomeVisible(genericTrueDriver)

      let reloadTriggerArray = [inForegroundTriggerDriver, reachableTriggerDriver, staleTriggerDriver, visibleTriggerDriver]

      reloadTriggerArray.reloadTrigger.drive(onNext: { _ in
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }
}
