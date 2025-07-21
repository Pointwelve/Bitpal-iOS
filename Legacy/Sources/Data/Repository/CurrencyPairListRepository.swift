//
//  CurrencyPairListRepository.swift
//  Data
//
//  Created by James Lai on 17/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias CurrencyPairListRepositoryType = Gettable

class CurrencyPairListRepository: CurrencyPairListRepositoryType {
   typealias Key = String
   typealias Value = CurrencyPairList

   fileprivate let memory: MemoryCache<String, CurrencyPairListData>
   fileprivate let cache: BasicCache<String, CurrencyPairListData>
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<CurrencyPairListData, CurrencyPairList>

   init(apiClient: APIClient, storage: CurrencyPairListStorage) {
      entityTransformer = DomainTransformer.currencyPairList()
      memory = MemoryCache<String, CurrencyPairListData>()
      let network = NetworkDataSource(apiClient: apiClient,
                                      keyTransformer: RouterTransformer.currencyPairList(),
                                      valueTransformer: JsonTransformer.currencyPairList())
      cache = CacheFactory.orchestratedVolatileCache(memory: memory,
                                                     disk: storage,
                                                     network: network,
                                                     expiry: 60 * 60 * 12,
                                                     maximumSize: 1)
   }
}

extension CurrencyPairListRepository {
   func get(_ key: String) -> Observable<CurrencyPairList> {
      return cache
         .get(key)
         .flatMap(entityTransformer.transform)
   }
}
