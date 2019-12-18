//
//  RxRelatedExt-Test.swift
//  App
//
//  Created by Alvin Choo on 23/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import RxCocoa
import RxSwift
import XCTest

class RxRelatedExt_Test: XCTestCase {
   private let disposeBag = DisposeBag()

   func testNotObservable() {
      let falseObservable = Observable.just(false)
      let expect = expectation(description: "executed")

      falseObservable.not().subscribe(onNext: { value in
         XCTAssertTrue(value)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testNotDriver() {
      let falseDriver = Observable.just(false).asDriver(onErrorJustReturn: false)
      let expect = expectation(description: "executed")

      falseDriver.not().drive(onNext: { value in
         XCTAssertTrue(value)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testOptionalObservable() {
      let falseObservable = Observable.just(true)
      let expect = expectation(description: "executed")

      falseObservable.asOptional().subscribe(onNext: { value in
         XCTAssertTrue(value == true)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testOptionalNilObservable() {
      let falseObservable = Observable.just(true)
      let expect = expectation(description: "executed")

      falseObservable.asTypeErasedDriver().drive(onNext: { _ in
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testOptionalDriver() {
      let falseDriver = Observable.just(true).asDriver(onErrorJustReturn: false)
      let expect = expectation(description: "executed")

      falseDriver.asOptional().drive(onNext: { value in
         XCTAssertTrue(value == true)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testVoidObservable() {
      let falseObservable = Observable.just(false)
      let expect = expectation(description: "executed")

      falseObservable.void().subscribe(onNext: { _ in
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testVoidDriver() {
      let falseDriver = Observable.just(false).asDriver(onErrorJustReturn: false)
      let expect = expectation(description: "executed")

      falseDriver.void().drive(onNext: { _ in
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testIfTrueObservable() {
      let falseObservable = Observable.just(true)
      let expect = expectation(description: "executed")

      falseObservable.ifTrue().subscribe(onNext: { value in
         XCTAssertTrue(value)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testIfFalseObservable() {
      let falseObservable = Observable.just(false)
      let expect = expectation(description: "executed")

      falseObservable.ifFalse().subscribe(onNext: { value in
         XCTAssertFalse(value)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testIfTrueDriver() {
      let falseDriver = Observable.just(true).asDriver(onErrorJustReturn: true)
      let expect = expectation(description: "executed")

      falseDriver.ifTrue().drive(onNext: { value in
         XCTAssertTrue(value)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }

   func testIfFalseDriver() {
      let falseDriver = Observable.just(false).asDriver(onErrorJustReturn: false)
      let expect = expectation(description: "executed")

      falseDriver.ifFalse().drive(onNext: { value in
         XCTAssertFalse(value)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }
}
