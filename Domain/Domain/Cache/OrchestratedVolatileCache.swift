//
//  OrchestratedVolatileCache.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

/// This cache behaves quite uniquely and as such needs to be orchestrated in order to ensure the correct behaviour.
/// Memory cache has items lazily loaded from the disk cache, therefore it's representation cannot be trusted
/// for maximum size constraint.
/// Cache expiry should purge from disk and memory.
public class OrchestratedVolatileCache<K, V: Modifiable, M: Cache, D: Cache>: Cache
   where M.Key == K, M.Value == V, D.Key == K, D.Value == V {
   public typealias Key = K
   public typealias Value = V

   private let maximumSize: Int
   private let timeLimit: TimeInterval
   public let memory: M
   public let disk: D

   public init(maximumSize: Int, expiry: TimeInterval, memory: M, disk: D) {
      self.maximumSize = maximumSize
      self.memory = memory
      self.disk = disk
      timeLimit = expiry
   }

   public func keyValues() -> Observable<[(K, V)]> {
      // Ignore memory cache, rely on disk cache as memory cache is lazily loaded.
      return disk.keyValues()
   }

   public func get(_ key: K) -> Observable<V> {
      // swiftlint:disable identifier_name
      let _disk = disk
      let _memory = memory
      let _timeLimit = timeLimit
      let _delete = delete
      return memory.get(key)
         .catchError { _ -> Observable<V> in
            _disk.get(key)
               .flatMap { element in
                  _memory.set(element, for: key)
                     .map { _ in element }
               }
         }
         .flatMap { element -> Observable<V> in
            let elapsed = Date().timeIntervalSince(element.modifyDate) - _timeLimit
            if elapsed >= 0 {
               debugPrint("Expired \(Mirror(reflecting: element).subjectType) after \(elapsed + _timeLimit)")
               return _delete(key)
                  .flatMap { _ in Observable.error(CacheError.expired) }
                  .catchError { _ in Observable.error(CacheError.expired) }
            } else {
               return .just(element)
            }
         }
   }

   public func delete(_ key: K) -> Observable<Void> {
      // This method might return an error, but only if the deletion
      // from disk fails.
      let _disk = disk
      return memory.delete(key)
         // Memory might not have the key we are trying to delete
         // so lets catch the error and delete from disk.
         .catchError { _ -> Observable<Void> in
            _disk.delete(key)
         }
         // In the event that memory does have a value we should
         // run the disk delete afterwards.
         .flatMap { _ -> Observable<Void> in
            _disk.delete(key)
         }
   }

   private func setToDiskAndMemory(_ value: V, for key: K) -> Observable<Void> {
      let _memory = memory
      let _disk = disk
      let _maxSize = maximumSize

      return _memory.set(value, for: key)
         .flatMap {
            _disk.set(value, for: key)
         }
         .catchError { _ -> Observable<Void> in
            _memory.delete(key)
         }
         .flatMap {
            _memory.keyValues().flatMap { (items) -> Observable<Void> in
               guard items.count > _maxSize else {
                  return .just(())
               }
               let sorted = items.sorted(by: { $0.1.modifyDate > $1.1.modifyDate })
               var observables = [Observable<Void>]()
               if var index = sorted.indices.last {
                  while index >= _maxSize {
                     let key = sorted[index].0
                     observables.append(_memory.delete(key).catchErrorJustReturn(()))
                     debugPrint("Deleted memory item, limit is: \(_maxSize)")
                     index = index.advanced(by: -1)
                  }
               }
               return .concat(observables)
            }
         }
         .flatMap {
            _disk.keyValues().flatMap { (items) -> Observable<Void> in
               guard items.count > _maxSize else {
                  return .just(())
               }
               let sorted = items.sorted(by: { $0.1.modifyDate > $1.1.modifyDate })
               var observables = [Observable<Void>]()
               if var index = sorted.indices.last {
                  while index >= _maxSize {
                     let key = sorted[index].0
                     observables.append(_disk.delete(key).catchErrorJustReturn(()))
                     debugPrint("Deleted disk item, limit is: \(_maxSize)")
                     index = index.advanced(by: -1)
                  }
               }
               return .concat(observables)
            }
         }
   }

   public func set(_ value: V, for key: K) -> Observable<Void> {
      // If the value has conformed to Emptyable
      if let emptyableValue = value as? Emptyable {
         // And if it is considered `empty` then we dont save it to memory and disk
         // Otherwise we do
         return emptyableValue.isEmpty ? .just(()) : setToDiskAndMemory(value, for: key)
      } else {
         // If value has not conformed to Emptyable
         // Then we always set it to memory and disk
         return setToDiskAndMemory(value, for: key)
      }
   }

   public func clear() {
      // Highly unlikely we'd want to clear disk here
      memory.clear()
   }

   public func onMemoryWarning() {
      // We should be a good iOS citizen and dump our memory when we receive a memory warning.
      memory.clear()
   }
}
