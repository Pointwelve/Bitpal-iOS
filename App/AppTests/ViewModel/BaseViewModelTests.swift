//
//  BaseViewModelTests.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift
import RxTest
import XCTest

@testable import App

class BaseViewModelTestCase: XCTestCase {
   var disposeBag: DisposeBag!
   var scheduler: TestScheduler!
   var preferences: TestableAppPreferences!

   override func setUp() {
      super.setUp()
      preferences = TestableAppPreferences()
      scheduler = TestScheduler(initialClock: 0)
      disposeBag = DisposeBag()
   }

   override func tearDown() {
      super.tearDown()
      preferences = nil
      scheduler = nil
      disposeBag = nil
   }
}
