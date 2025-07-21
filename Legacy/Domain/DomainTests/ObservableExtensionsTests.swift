//
//  ObservableExtensionsTest.swift
//  Domain
//
//  Created by Ryne Cheow on 23/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

private enum ObservableError: Error {
   case testError
}

class ObservableExtensionsTest: XCTestCase {
   let disposeBag = DisposeBag()

   fileprivate func throwingFunction() throws -> String {
      throw ObservableError.testError
   }

   func testJustTryErroredObservable() {
      let errorableObservable = Observable<String>.justTry {
         throw ObservableError.testError
      }

      let expect = expectation(description: "Just try error")

      errorableObservable
         .subscribe(onNext: { _ in
            XCTFail("Should not emit any item.")
         }, onError: { _ in
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testJustTrySuccessfulObservable() {
      let observable = Observable<String>.justTry {
         "success"
      }

      let expect = expectation(description: "Just try success")

      observable
         .subscribe(onNext: { text in
            XCTAssertEqual(text, "success")
            expect.fulfill()
         }, onError: { error in
            XCTFail("Should not error out: \(error)")
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 5) { error in
         XCTAssertNil(error)
      }
   }

   func testTryErroredObservable() {
      let errorableObservable = Observable<String>.try {
         throw ObservableError.testError
      }

      let expect = expectation(description: "Just try error")

      errorableObservable
         .subscribe(onNext: { _ in
            XCTFail("Should not emit any item.")
         }, onError: { _ in
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testTrySuccessfulObservable() {
      let observable = Observable<String>.try {
         Observable.just("success")
      }

      let expect = expectation(description: "Just try error")

      observable
         .subscribe(onNext: { text in
            XCTAssertEqual(text, "success")
            expect.fulfill()
         }, onError: { error in
            XCTFail("Should not error out: \(error)")
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 5) { error in
         XCTAssertNil(error)
      }
   }

   func testRetryOnError() {
      var testCount = 2
      let errorableObservable = Observable<String>.deferred {
         Observable<String>.create {
            observer in
            testCount -= 1
            if testCount < 1 {
               observer.on(.next("success"))
            } else {
               observer.on(.error(ObservableError.testError))
            }
            return Disposables.create()
         }
      }

      let expect = expectation(description: "Retry on Error")

      errorableObservable
         .retryOnError(every: 1)
         .subscribe(onNext: { text in
            XCTAssertEqual(text, "success")
            expect.fulfill()
         }, onError: { error in
            XCTFail("Should not error out: \(error)")
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 2) { error in
         XCTAssertNil(error)
      }
   }

   func testCatchErrorJustComplete() {
      let errorableObservable = Observable<String>.deferred {
         Observable<String>.create {
            observer in
            observer.on(.error(ObservableError.testError))

            return Disposables.create()
         }
      }

      let expect = expectation(description: "On Error just Complete")

      errorableObservable
         .catchErrorJustComplete()
         .subscribe(onNext: { _ in
            XCTFail("Should not got event on next")
         }, onCompleted: {
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 2) { error in
         XCTAssertNil(error)
      }
   }
}
