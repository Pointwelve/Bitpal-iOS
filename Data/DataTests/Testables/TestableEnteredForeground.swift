//
//  TestableEnteredForeground.swift
//  Data
//
//  Created by Alvin Choo on 18/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class TestableEnteredForeground {
   let triggerEnteredForeground = BehaviorRelay<Void>(value: ())
   let onEnteredForeground: Observable<Void>

   init() {
      onEnteredForeground = triggerEnteredForeground.asObservable()
   }
}
