//
//  TestableReachabilityProvider.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Alamofire
@testable import Data
import Foundation
import RxSwift
import XCTest

final class TestableReachabilityProvider: ReachabilityProvider {
   var retryInterval: Int {
      return 1
   }

   var isOnline: Observable<Bool> {
      return Observable.from([false, false, false, false, true]).catchErrorJustReturn(true)
   }
}
