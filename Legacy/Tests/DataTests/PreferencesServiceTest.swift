//
//  PreferencesServiceTest.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RxSwift
import XCTest

private enum PreferencesError: Error {
   case fail
}

private class PreferencesTestSuccessRepository: PreferencesRepositoryType {
   typealias Value = Preferences
   typealias Key = Void

   func write(_ newValue: Preferences) -> Observable<Preferences> {
      return Observable.just(newValue)
   }

   func read() -> Observable<Preferences> {
      return Observable.just(Preferences(language: .default))
   }
}

private class PreferencesTestFailureRepository: PreferencesRepositoryType {
   typealias Value = Preferences
   typealias Key = Void

   func write(_ newValue: Preferences) -> Observable<Preferences> {
      return Observable.error(PreferencesError.fail)
   }

   func read() -> Observable<Preferences> {
      return Observable.error(PreferencesError.fail)
   }
}

class PreferencesUseCaseTests: XCTestCase {
   func testReadPreferencesReturnsObject() {
      let disposeBag = DisposeBag()
      let repository = PreferencesTestSuccessRepository()
      let service = ReadPreferencesUseCaseType(repository: repository, schedulerExecutor: ImmediateSchedulerExecutor())
      let expect = expectation(description: "executed")

      service.read()
         .subscribe(onNext: { _ in
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testReadPreferencesResultsInError() {
      let disposeBag = DisposeBag()
      let repository = PreferencesTestFailureRepository()
      let service = ReadPreferencesUseCaseType(repository: repository, schedulerExecutor: ImmediateSchedulerExecutor())
      let expect = expectation(description: "executed")

      service.read()
         .subscribe(onError: { _ in
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testWritePreferencesReturnsObject() {
      let disposeBag = DisposeBag()
      let repository = PreferencesTestSuccessRepository()
      let service = WritePreferencesUseCaseType(repository: repository, schedulerExecutor: ImmediateSchedulerExecutor())
      let expect = expectation(description: "executed")

      service.write(Preferences(language: .default))
         .subscribe(onNext: { _ in
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testWritePreferencesResultsInError() {
      let disposeBag = DisposeBag()
      let repository = PreferencesTestFailureRepository()
      let service = WritePreferencesUseCaseType(repository: repository, schedulerExecutor: ImmediateSchedulerExecutor())
      let expect = expectation(description: "executed")

      service.write(Preferences(language: .default))
         .subscribe(onError: { _ in
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}
