//
//  Cache.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public protocol Cache {
   associatedtype Key
   associatedtype Value

   /// Asks the cache to provide all key-values.
   /// - returns: Key-value pairs.
   func keyValues() -> Observable<[(Key, Value)]>

   /// Asks the cache to get the value for a given key.
   /// - parameter key: The key you want to get the value for.
   func get(_ key: Key) -> Observable<Value>

   /// Asks the cache to set a value for the given key.
   /// - parameter value: The value to set on the cache.
   /// - parameter key: The key to use for the given value.
   @discardableResult func set(_ value: Value, for key: Key) -> Observable<Void>

   /// Asks the cache to delete a value for a given key.
   /// - parameter key: The key associated with the value to delete.
   @discardableResult func delete(_ key: Key) -> Observable<Void>

   /// Asks the cache to be cleared.
   func clear()

   /// Notifies the cache that a memory warning was thrown, and asks it to do its best to clean some memory.
   func onMemoryWarning()
}

extension Cache {
   /// Compose with another cache.
   /// - parameter other: Cache to compose with.
   /// - returns: `BasicCache` composed of `self` and `other`.
   public func compose<B: Cache>(_ other: B) -> BasicCache<Self.Key, Self.Value>
      where Self.Key == B.Key, Self.Value == B.Value {
      return BasicCache(keyValues: {
         // Check first cache
         self.keyValues()
            // Not found, fallback to second cache
            .catchError { _ in other.keyValues() }
      }, get: { k in
         // Check first cache
         self.get(k)
            .catchError { _ in
               // Not found, fallback to second cache
               other.get(k)
                  .flatMap { v in
                     // Store in first cache to provide quicker fetching next time
                     self.set(v, for: k)
                        .map { _ in v }
                  }
            }
      }, set: { v, k in
         // Cascade set the new value
         self.set(v, for: k)
            .flatMap { other.set(v, for: k) }
      }, delete: { k in
         // Cascade delete the value
         self.delete(k)
            .flatMap { other.delete(k) }
      }, clear: {
         self.clear()
         other.clear()
      }, onMemoryWarning: {
         self.onMemoryWarning()
         other.onMemoryWarning()
      })
   }
}
