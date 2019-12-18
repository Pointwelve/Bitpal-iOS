//
//  TestableEnteredBackground.swift
//  Data
//
//  Created by Alvin Choo on 18/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class TestableEnteredBackground {
   let triggerEnteredBackground = BehaviorRelay<Void>(value: ())
   let onEnteredBackground: Observable<Void>

   init() {
      onEnteredBackground = triggerEnteredBackground.asObservable()
   }
}
