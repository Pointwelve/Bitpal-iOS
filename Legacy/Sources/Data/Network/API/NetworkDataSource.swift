//
//  NetworkDataSource.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

class NetworkDataSource<K, V, F: APIClient>: FailingCache<K, V> {
   private let apiClient: F
   private let keyTransformers: [() -> (ValueTransformerBox<Key, F.Key>)]
   private let valueTransformer: (Key) -> (ValueTransformerBox<F.Value, Value>)

   convenience init(apiClient: F,
                    keyTransformer: @escaping () -> ValueTransformerBox<Key, F.Key>,
                    valueTransformer: @escaping (Key) -> ValueTransformerBox<F.Value, Value>) {
      self.init(apiClient: apiClient,
                keyTransformers: [keyTransformer],
                valueTransformer: valueTransformer)
   }

   init(apiClient: F,
        keyTransformers: [() -> ValueTransformerBox<Key, F.Key>],
        valueTransformer: @escaping (Key) -> ValueTransformerBox<F.Value, Value>) {
      self.apiClient = apiClient
      self.keyTransformers = keyTransformers
      self.valueTransformer = valueTransformer
   }

   override func get(_ key: Key) -> Observable<Value> {
      let apiWork = keyTransformers.map {
         $0().transform(key)
            .flatMap(apiClient.executeRequest)
            // RxAlamofire puts us back on the main thread here, so lets just kick it back to a background thread
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
      }

      let apiCount = apiWork.count
      return apiCount == 1 ?
         // If there is only 1 api involved, we dont need to use combineLatest
         apiWork.first!
         .flatMap(valueTransformer(key).transform) :
         // If there is more than 1 api, need to use combine latest
         Observable.combineLatest(apiWork)
         .flatMap(valueTransformer(key).transform)
   }

   override func set(_ value: V, for key: K) -> Observable<Void> {
      return Observable.empty()
   }

   func asBasicCache() -> BasicCache<K, V> {
      return BasicCache(cache: self)
   }
}
