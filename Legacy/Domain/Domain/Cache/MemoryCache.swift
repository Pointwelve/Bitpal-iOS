//
//  MemoryCache.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public class MemoryCache<K, V>: Cache where K: Hashable {
   public typealias Key = K
   public typealias Value = V

   public init() {}

   let semaphore = DispatchSemaphore(value: 1)

   private var values = [Key: Value]()

   public func keyValues() -> Observable<[(K, V)]> {
      semaphore.wait()
      defer {
         semaphore.signal()
      }
      let keyValues = values.map {
         ($0, $1)
      }
      return Observable.just(keyValues)
   }

   private func debugCount() {
      debugPrint("\(Value.self) count in memory: \(values.count)")
   }

   public func get(_ key: Key) -> Observable<Value> {
      semaphore.wait()
      defer {
         semaphore.signal()
      }
      guard let value = values[key] else {
         return Observable.error(CacheError.notFound)
      }
      return Observable.just(value)
   }

   public func set(_ value: Value, for key: Key) -> Observable<Void> {
      semaphore.wait()
      defer {
         debugCount()
         semaphore.signal()
      }
      values[key] = value

      return Observable.just(())
   }

   public func delete(_ key: K) -> Observable<Void> {
      semaphore.wait()
      defer {
         debugCount()
         semaphore.signal()
      }
      guard values.removeValue(forKey: key) != nil else {
         return Observable.error(CacheError.notFound)
      }
      return Observable.just(())
   }

   public func clear() {
      semaphore.wait()
      defer {
         debugCount()
         semaphore.signal()
      }
      values.removeAll()
   }

   public func onMemoryWarning() {
      semaphore.wait()
      defer {
         debugCount()
         semaphore.signal()
      }
      values.removeAll()
   }
}
