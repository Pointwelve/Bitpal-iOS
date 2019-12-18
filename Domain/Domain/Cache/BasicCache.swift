//
//  BasicCache.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public func + <K, V, T: Cache, U: Cache>(lhs: T, rhs: U) -> BasicCache<K, V>
   where T.Key == K, U.Key == T.Key, T.Value == V, U.Value == T.Value {
   return lhs.compose(rhs)
}

public func += <K, V, T: Cache, U: Cache>(lhs: inout T, rhs: U)
   where T.Key == K, U.Key == T.Key, T.Value == V, U.Value == T.Value {
   // swiftlint:disable force_cast
   lhs = lhs.compose(rhs) as! T
}

public struct BasicCache<K, V>: Cache {
   public typealias Key = K
   public typealias Value = V

   public typealias GetClosure = (_ key: K) -> Observable<V>
   public typealias SetClosure = (_ value: V, _ key: K) -> Observable<Void>
   public typealias DeleteClosure = (_ key: K) -> Observable<Void>
   public typealias ExpiredClosure = (_ key: K) -> Observable<Bool>
   public typealias VoidClosure = () -> Void
   public typealias KeyValuesClosure = () -> Observable<[(K, V)]>

   internal let keyValuesClosure: KeyValuesClosure
   internal let getClosure: GetClosure
   internal let setClosure: SetClosure
   internal let deleteClosure: DeleteClosure
   internal let clearClosure: VoidClosure
   internal let memoryClosure: VoidClosure

   /// Initializes a new instance of a `BasicCache` specifying closures for `keyValues`,
   /// `get`, `set`, `delete`, `clear` and `onMemoryWarning`, thus determining the behavior of the cache as a whole.
   /// - parameter keyValues: The closure to execute when you call `keyValues()` on this instance.
   /// - parameter get: The closure to execute when you call `get(key)` on this instance.
   /// - parameter set: The closure to execute when you call `set(value, key)` on this instance.
   /// - parameter delete: The closure to execute when you call `delete(key)` on this instance.
   /// - parameter clear: The closure to execute when you call `clear()` on this instance.
   /// - parameter onMemoryWarning: The closure to execute when you call `onMemoryWarning()` on this instance,
   /// or when a memory warning is thrown by the system and the cache is listening for memory pressure events.\

   public init(keyValues keyValuesClosure: @escaping KeyValuesClosure,
               get getClosure: @escaping GetClosure,
               set setClosure: @escaping SetClosure,
               delete deleteClosure: @escaping DeleteClosure,
               clear clearClosure: @escaping VoidClosure = {},
               onMemoryWarning memoryClosure: @escaping VoidClosure = {}) {
      self.keyValuesClosure = keyValuesClosure
      self.getClosure = getClosure
      self.setClosure = setClosure
      self.deleteClosure = deleteClosure
      self.clearClosure = clearClosure
      self.memoryClosure = memoryClosure
   }

   /// Initializes a new instance of a `BasicCache` by copying the closures for `keyValues`,
   /// `get`, `set`, `delete`, `clear` and `onMemoryWarning` from the passed in `cache` object, thus
   /// determining the behavior of the cache as a whole.
   /// - parameter cache: The cache to encapsulate.
   public init<C: Cache>(cache: C) where C.Key == K, C.Value == V {
      keyValuesClosure = cache.keyValues
      getClosure = cache.get
      setClosure = cache.set
      deleteClosure = cache.delete
      clearClosure = cache.clear
      memoryClosure = cache.onMemoryWarning
   }

   /// Asks the cache to provide all key-values.
   /// - returns: Key-value pairs.
   /// - returns: The result of the keyValuesClosure specified when initializing the instance
   public func keyValues() -> Observable<[(K, V)]> {
      return keyValuesClosure()
   }

   /// Asks the cache to get the value for a given key.
   /// - parameter key: The key you want to get the value for.
   /// - returns: The result of the getClosure specified when initializing the instance
   public func get(_ key: K) -> Observable<V> {
      return getClosure(key)
   }

   /// Asks the cache to set a value for the given key.
   /// - parameter value: The value to set on the cache.
   /// - parameter key: The key to use for the given value.
   /// This call executes the setClosure specified when initializing the instance.
   public func set(_ value: V, for key: K) -> Observable<Void> {
      return setClosure(value, key)
   }

   /// Asks the cache to delete a value for a given key.
   /// - parameter key: The key associated with the value to delete.
   /// This call executes the deleteClosure specified when initializing the instance.
   public func delete(_ key: K) -> Observable<Void> {
      return deleteClosure(key)
   }

   /// Asks the cache to clear its contents
   /// This call executes the clearClosure specified when initializing the instance
   public func clear() {
      clearClosure()
   }

   /// Tells the cache that a memory warning event was received
   /// This call executes the memoryClosure specified when initializing the instance
   public func onMemoryWarning() {
      memoryClosure()
   }
}
