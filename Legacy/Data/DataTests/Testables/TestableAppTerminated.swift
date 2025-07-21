//
//  TestableAppTerminated.swift
//  Data
//
//  Created by Alvin Choo on 18/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class TestableAppTerminated {
   let triggerAppTerminated = BehaviorRelay<Void>(value: ())
   let onAppTerminated: Observable<Void>

   init() {
      onAppTerminated = triggerAppTerminated.asObservable()
   }
}
