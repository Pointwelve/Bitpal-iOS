//
//  PushNotificationUseCaseCoordinatorTests.swift
//  DomainTests
//
//  Created by Ryne Cheow on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class PushNotificationUseCaseCoordinatorTests: RxTestCase {
   func testPushNotificationRegistrationUseCaseExecuted() {
      let expect = expectation(description: "read is loading")
      let token = "test"

      let testableGetAction: (String) -> Observable<Void> = { _ in
         .just(())
      }

      let coordinator = PushNotificationUseCaseCoordinator(request: token, getAction: testableGetAction)

      coordinator.getResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(_, condition):
                  switch condition {
                  case .full:
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

   func testPushNotificationRegistrationUseCaseExecutedWithNetworkError() {
      let expect = expectation(description: "Offline error received")
      let token = "test"
      let testableGetAction: (String) -> Observable<Void> = { _ in
         Observable.error(NSError.networkUnreachableError)
      }

      let coordinator = PushNotificationUseCaseCoordinator(request: token, getAction: testableGetAction)

      coordinator.getResult()
         .subscribe(onNext: { result in
            switch result {
            case let .failure(failure):
               switch failure {
               case .offline:
                  expect.fulfill()
               default:
                  break
               }
            default:
               break
            }
         })
         .disposed(by: disposeBag)

      waitForExpectations(timeout: 1, handler: { _ in })
   }
}
