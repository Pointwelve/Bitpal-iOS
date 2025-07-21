//
//  RxTestCase.swift
//  Domain
//
//  Created by Ryne Cheow on 12/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift
import XCTest

class RxTestCase: XCTestCase {
   var disposeBag: DisposeBag!

   override func setUp() {
      super.setUp()
      disposeBag = DisposeBag()
   }

   override func tearDown() {
      super.tearDown()
      disposeBag = nil
   }
}
