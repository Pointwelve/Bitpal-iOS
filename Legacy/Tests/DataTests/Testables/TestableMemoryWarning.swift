//
//  TestableMemoryWarning.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class TestableMemoryWarning {
   let triggerMemoryWarning = BehaviorRelay<Bool>(value: false)
   let onMemoryWarning: Observable<Void>

   init() {
      onMemoryWarning = triggerMemoryWarning.asObservable().map { _ in Void() }
   }
}
