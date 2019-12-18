//
//  SocketDataSource.swift
//  Data
//
//  Created by Ryne Cheow on 18/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

final class SocketDataSource<K, V, F: SocketClient>: FailingCache<K, V> {
   private let apiClient: F
   private let keyTransformer: () -> (ValueTransformerBox<Key, F.Key>)
   private let valueTransformer: (Key) -> (ValueTransformerBox<F.Value, Value>)

   init(apiClient: F,
        keyTransformer: @escaping () -> ValueTransformerBox<Key, F.Key>,
        valueTransformer: @escaping (Key) -> ValueTransformerBox<F.Value, Value>) {
      self.apiClient = apiClient
      self.keyTransformer = keyTransformer
      self.valueTransformer = valueTransformer
   }

   override func get(_ key: Key) -> Observable<Value> {
      return keyTransformer().transform(key)
         .flatMap(apiClient.executeRequest)
         // RxAlamofire puts us back on the main thread here, so lets just kick it back to a background thread
         .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
         .flatMap(valueTransformer(key).transform)
   }

   // Overrided to avoid errors.
   override func set(_ value: V, for key: K) -> Observable<Void> {
      return Observable.empty()
   }

   func asBasicCache() -> BasicCache<K, V> {
      return BasicCache(cache: self)
   }
}
