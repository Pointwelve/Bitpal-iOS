//
//  ConfigurationDataRepositoryTests.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RxSwift
import XCTest

private class TestableConfigurationLocalDataStorage: ConfigurationStorage {
   override func get(_ key: String) -> Observable<ConfigurationData> {
      return Observable.just(ConfigurationData(apiHost: "test.test",
                                               functionsHost: "www.func.com",
                                               socketHost: "socket.host",
                                               sslCertificateData: Data(),
                                               
                                               companyName: "testName",
                                               termsAndConditions: "foobar"))
   }
}

class ConfigurationRepositoryTests: XCTestCase {
   func testConfigurationRepositoryReadResultsInError() {
      let storage = ConfigurationStorage()
      let repository = ConfigurationRepository(storage: storage)
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

   func testConfigurationRepositoryReadResultsInObject() {
      let storage = TestableConfigurationLocalDataStorage()
      let repository = ConfigurationRepository(storage: storage)
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
}
