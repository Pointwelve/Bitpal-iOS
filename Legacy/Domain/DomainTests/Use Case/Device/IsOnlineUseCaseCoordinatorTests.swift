//
//  IsOnlineUseCaseCoordinatorTests.swift
//  Domain
//
//  Created by Ryne Cheow on 8/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class IsOnlineUseCaseCoordinatorTests: RxTestCase {
   func testGetResponseReturnsTrue() {
      let expect = expectation(description: "online")
      let coordinator = IsOnlineUseCaseCoordinator(getAction: { .just(true) })
      coordinator.getResult()
         .subscribe(onNext: { result in
            if result.contentValue?.isOnline == true {
               expect.fulfill()
            }
         })
         .disposed(by: disposeBag)
      waitForExpectations(timeout: 1, handler: { _ in })
   }

   func testGetResponseReturnsFalse() {
      let expect = expectation(description: "offline")
      let coordinator = IsOnlineUseCaseCoordinator(getAction: { .just(false) })
      coordinator.getResult()
         .subscribe(onNext: { result in
            if result.hasContent, result.contentValue?.isOnline == false {
               expect.fulfill()
            }
         })
         .disposed(by: disposeBag)
      waitForExpectations(timeout: 1, handler: { _ in })
   }

   func testGetBeginsWithLoading() {
      let expect = expectation(description: "loading")
      let coordinator = IsOnlineUseCaseCoordinator(getAction: { .never() })
      coordinator.getResult()
         .subscribe(onNext: { result in
            if result.isLoading {
               expect.fulfill()
            }
         })
         .disposed(by: disposeBag)
      waitForExpectations(timeout: 1, handler: { _ in })
   }
}
