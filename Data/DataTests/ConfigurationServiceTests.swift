//
//  ConfigurationServiceTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RxSwift
import XCTest

private enum ReadError: Error {
   case fail
}

private class ReadConfigurationTestSuccessRepository: Readable {
   typealias Value = Configuration
   typealias Key = Void

   func read() -> Observable<Configuration> {
      return Observable.just(Configuration(apiHost: "test",
                                           functionsHost: "www.func.com",
                                           socketHost: "testhost",
                                           sslCertificateData: Data(),
                                           
                                           companyName: "testName",
                                           termsAndConditions: "foobar"))
   }
}

private class ReadConfigurationTestFailureRepository: Readable {
   typealias Value = Configuration
   typealias Key = Void

   func read() -> Observable<Configuration> {
      return Observable.error(ReadError.fail)
   }
}

class ConfigurationUseCaseTests: XCTestCase {
   func testReadConfigurationReturnsObject() {
      let disposeBag = DisposeBag()
      let repository = ReadConfigurationTestSuccessRepository()
      let service = ReadConfigurationUseCaseType(repository: repository, schedulerExecutor: ImmediateSchedulerExecutor())
      let expect = expectation(description: "executed")

      service.read().subscribe(onNext: { _ in
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }

   func testReadConfigurationResultsInError() {
      let disposeBag = DisposeBag()
      let repository = ReadConfigurationTestFailureRepository()
      let service = ReadConfigurationUseCaseType(repository: repository, schedulerExecutor: ImmediateSchedulerExecutor())
      let expect = expectation(description: "executed")

      service.read().subscribe(onError: { _ in
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}
