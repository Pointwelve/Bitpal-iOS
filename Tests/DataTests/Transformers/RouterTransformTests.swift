//
//  RouterTransformTests.swift
//  Data
//
//  Created by Alvin Choo on 25/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RxSwift
import XCTest

class RouterTransformTests: XCTestCase {
   private let disposeBag = DisposeBag()

   enum TestRouter: Router {
      var parameters: [String: Any]? {
         return nil
      }

      case test

      var method: HTTPMethodType {
         return .get
      }

      var relativePath: String {
         return ""
      }
   }

   func testMakeTransformer() {
      let valueBox = RouterTransformer.makeRouterTransformer { _ -> Router in
         TestRouter.test
      }

      let expect = expectation(description: "executed")

      valueBox().transform("test").subscribe(onNext: { router in
         switch router {
         case TestRouter.test:
            XCTAssertTrue(true)
         default:
            XCTFail()
         }
         expect.fulfill()
      }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1.0) { error in
         XCTAssertNil(error)
      }
   }
}
