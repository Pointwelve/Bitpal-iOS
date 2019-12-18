//
//  UseCaseTest.swift
//  Domain
//
//  Created by Ryne Cheow on 5/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class TestRepository: Readable, Writeable, Gettable, Settable, Expirable {
   typealias Key = String
   typealias Value = String

   func read() -> Observable<String> {
      return .just("read")
   }

   func write(_ value: String) -> Observable<String> {
      return .just("written")
   }

   func get(_ key: String) -> Observable<String> {
      return .just("got")
   }

   func set(_ value: String, for key: String) -> Observable<String> {
      return .just("set")
   }

   func hasExpired(_ key: String) -> Observable<String> {
      return .just("not expired")
   }
}

class TestUseCase<T: Actionable>: UseCaseType {
   public typealias Repository = T
   public typealias Key = T.Key
   public typealias Value = T.Value
   public let repository: Repository

   init(repository: Repository) {
      self.repository = repository
   }

   public func execute<U>(method: @escaping () -> Observable<U>) -> Observable<U> {
      return method()
   }
}

class TestReadUseCase<T: Readable>: TestUseCase<T>, Readable {}
class TestWriteUseCase<T: Writeable>: TestUseCase<T>, Writeable {}
class TestSetUseCase<T: Settable>: TestUseCase<T>, Settable {}
class TestGetUseCase<T: Gettable>: TestUseCase<T>, Gettable {}
class TestHasExpiredUseCase<T: Expirable>: TestUseCase<T>, Expirable {}

class UseCaseTests: XCTestCase {
   var disposeBag: DisposeBag!

   override func setUp() {
      disposeBag = DisposeBag()
   }

   override func tearDown() {
      disposeBag = nil
   }

   func testReadUseCaseCallsRepository() {
      let repository = TestRepository()
      let useCase = TestReadUseCase(repository: repository)
      useCase.read().subscribe(onNext: { value in
         XCTAssertEqual(value, "read")
      }).disposed(by: disposeBag)
   }

   func testWriteUseCaseCallsRepository() {
      let repository = TestRepository()
      let useCase = TestWriteUseCase(repository: repository)
      useCase.write("test").subscribe(onNext: { value in
         XCTAssertEqual(value, "written")
      }).disposed(by: disposeBag)
   }

   func testSetUseCaseCallsRepository() {
      let repository = TestRepository()
      let useCase = TestSetUseCase(repository: repository)
      useCase.set("value", for: "key").subscribe(onNext: { value in
         XCTAssertEqual(value, "set")
      }).disposed(by: disposeBag)
   }

   func testGetUseCaseCallsRepository() {
      let repository = TestRepository()
      let useCase = TestGetUseCase(repository: repository)
      useCase.get("test").subscribe(onNext: { value in
         XCTAssertEqual(value, "got")
      }).disposed(by: disposeBag)
   }

   func testHasExpiredUseCaseCallsRepository() {
      let repository = TestRepository()
      let useCase = TestHasExpiredUseCase(repository: repository)
      useCase.hasExpired("test").subscribe(onNext: { value in
         XCTAssertEqual(value, "not expired")
      }).disposed(by: disposeBag)
   }
}

class UseCaseExecutorTests: RxTestCase {
   func testIsRunningIsFalseOnInit() {
      let useCase = UseCaseExecutor<String, String>(schedulerExecutor: ImmediateSchedulerExecutor()) { () -> Observable<String> in
         Observable.just("test")
      }
      XCTAssertFalse(useCase.isRunning)
   }

   func testExecuteIsRunningDuringExecution() {
      let expect = expectation(description: "executed")
      let useCase = UseCaseExecutor<String, String>(schedulerExecutor: ImmediateSchedulerExecutor()) { () -> Observable<String> in
         Observable.just("test")
      }
      XCTAssertFalse(useCase.isRunning)
      Observable<String>.create { (observer) -> Disposable in
         useCase.execute(useCaseObserver: observer)
         XCTAssertTrue(useCase.isRunning)
         return Disposables.create()
      }.subscribe(onNext: { _ in
         XCTAssertFalse(useCase.isRunning)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testExecuteReturnsCorrectValue() {
      let expect = expectation(description: "executed")
      let useCase = UseCaseExecutor<String, String>(schedulerExecutor: ImmediateSchedulerExecutor()) { () -> Observable<String> in
         Observable.just("test")
      }

      Observable<String>.create { (observer) -> Disposable in
         useCase.execute(useCaseObserver: observer)
         return Disposables.create()
      }.subscribe(onNext: { value in
         XCTAssertEqual(value, "test")
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}
