//
//  ConfigurationUseCaseCoordinatorTests.swift
//  Domain
//
//  Created by Ryne Cheow on 6/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift
import XCTest

@testable import Domain

final class ConfigurationUseCaseCoordinatorTests: RxTestCase {
   func testGetResponseReturnsApiHost() {
      let expect = expectation(description: "Api Host")
      let configuration = Configuration(apiHost: "www.test.com",
                                        functionsHost: "www.func.com",
                                        socketHost: "www.socket.com",
                                        sslCertificateData: nil,
                                        companyName: "testName",
                                        apiKey: "apiKey",
                                        termsAndConditions: "foobar")

      let coordinator = ConfigurationUseCaseCoordinator(readAction: { .just(configuration) })
      XCTAssertTrue(coordinator.apiHost.isEmpty)

      coordinator.readResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertEqual("www.test.com",
                                    coordinator.apiHost)
                     expect.fulfill()
                  default:
                     break
                  }
               }

            default:
               break
            }
         })
         .disposed(by: disposeBag)
      waitForExpectations(timeout: 1, handler: { _ in })
   }

   func testGetResponseReturnsSocketHost() {
      let expect = expectation(description: "Socket Host")
      let configuration = Configuration(apiHost: "www.test.com",
                                        functionsHost: "www.func.com",
                                        socketHost: "www.socket.com",
                                        sslCertificateData: nil,
                                        companyName: "testName",
                                        apiKey: "apiKey",
                                        termsAndConditions: "foobar")

      let coordinator = ConfigurationUseCaseCoordinator(readAction: { .just(configuration) })
      XCTAssertTrue(coordinator.apiHost.isEmpty)

      coordinator.readResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertEqual("www.socket.com",
                                    coordinator.socketHost)
                     expect.fulfill()
                  default:
                     break
                  }
               }

            default:
               break
            }
         })
         .disposed(by: disposeBag)

      waitForExpectations(timeout: 1, handler: { _ in })
   }

   func testGetResponseReturnsTermsAndCondition() {
      let expect = expectation(description: "SSL Cert")
      let configuration = Configuration(apiHost: "www.test.com",
                                        functionsHost: "www.func.com",
                                        socketHost: "www.socket.com",
                                        sslCertificateData: nil,
                                        companyName: "testName",
                                        apiKey: "apiKey",
                                        termsAndConditions: "foobar")

      let coordinator = ConfigurationUseCaseCoordinator(readAction: { .just(configuration) })
      XCTAssertTrue(coordinator.apiHost.isEmpty)

      coordinator.readResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertEqual(coordinator.termsAndConditions, "foobar")
                     expect.fulfill()
                  default:
                     break
                  }
               }

            default:
               break
            }
         })
         .disposed(by: disposeBag)

      waitForExpectations(timeout: 1, handler: { _ in })
   }
}
