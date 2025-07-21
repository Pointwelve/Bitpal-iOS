//
//  FailingCache.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

open class FailingCache<K, V>: Cache {
   public typealias Key = K
   public typealias Value = V

   public init() {}

   open func keyValues() -> Observable<[(Key, Value)]> {
      return Observable.error(CacheError.invalid)
   }

   open func get(_ key: Key) -> Observable<Value> {
      return Observable.error(CacheError.invalid)
   }

   open func set(_ value: Value, for key: Key) -> Observable<Void> {
      return Observable.error(CacheError.invalid)
   }

   open func delete(_ key: Key) -> Observable<Void> {
      return Observable.error(CacheError.invalid)
   }

   open func clear() {
      // no op
   }

   open func onMemoryWarning() {
      // no op
   }
}
