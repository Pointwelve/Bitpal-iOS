//
//  TestableUseCaseProvider.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

class TestableUseCase<K, V>: Readable, Writeable, Settable, Gettable, Pageable, Updateable {
   typealias Key = K
   typealias Value = V

   var didRead: Bool = false
   var didWrite: Bool = false
   var didGet: Bool = false
   var didSet: Bool = false
   var didPage: Bool = false
   var didUpdate: Bool = false

   init() {}

   func read() -> Observable<V> {
      didRead = true
      return .empty()
   }

   func write(_ value: V) -> Observable<V> {
      didWrite = true
      return .empty()
   }

   func get(_ key: K) -> Observable<V> {
      didGet = true
      return .empty()
   }

   func set(_ value: V, for key: K) -> Observable<V> {
      didSet = true
      return .empty()
   }

   func nextPage(_ key: K) -> Observable<V> {
      didPage = true
      return .empty()
   }

   func update(_ key: K) -> Observable<V> {
      didUpdate = true
      return .empty()
   }
}
