//
//  TestableLocationProvider.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Bitpal
import Foundation
import RxCocoa
import RxSwift

class TestableLocationProvider: LocationProviderType {
   private let _state = BehaviorRelay<LocationProviderState>(value: .unknown)
   let state: Driver<LocationProviderState>

   init() {
      state = _state.asDriver()
   }

   var started: Bool = false
   var stopped: Bool = true
   var cancelled: Bool = false

   func stop() {
      stopped = true
      cancelled = false
      started = false
   }

   func start(timeout: TimeInterval) {
      started = true
      stopped = false
      cancelled = false
   }

   func cancel() {
      started = false
      stopped = false
      cancelled = true
   }
}
