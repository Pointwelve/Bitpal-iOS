//
//  IsOnlineDataRepositoryTests.swift
//  Data
//
//  Created by Alvin Choo on 25/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RxSwift
import XCTest

class IsOnlineDataRepositoryTests: XCTestCase {
   private let disposeBag = DisposeBag()

   func testReachabilityRead() {
      let provider = TestableReachabilityProvider()
      let isOnlineRepo = IsOnlineRepository(reachability: provider)

      let expect = expectation(description: "executed")

      isOnlineRepo.read().take(1).subscribe(onNext: { isOnline in
         XCTAssertFalse(isOnline)
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }
}
