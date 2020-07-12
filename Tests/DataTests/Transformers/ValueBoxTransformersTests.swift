//
//  ValueBoxTransformersTests.swift
//  Data
//
//  Created by Ryne Cheow on 25/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import RxSwift
import XCTest

class ValueBoxTransformersTests: XCTestCase {
   let disposeBag = DisposeBag()

   func testValueBoxTransformerTransform() {
      let intToStringTransformer = ValueTransformerBox<Int, String> {
         number in
         Observable.just("\(number)")
      }

      let expect = expectation(description: "Transform int to string int")
      intToStringTransformer
         .transform(123)
         .subscribe(onNext: {
            XCTAssertEqual("123", $0)
            expect.fulfill()
         }).disposed(by: disposeBag)

      waitForExpectations(timeout: 1) { error in
         XCTAssertNil(error)
      }
   }
}
