//
//  CurrencyDetailRepository.swift
//  Data
//
//  Created by Kok Hong Choo on 15/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias CurrencyDetailRepositoryType = Gettable

class CurrencyDetailRepository: CurrencyDetailRepositoryType {
   typealias Key = GetCurrencyDetailRequest
   typealias Value = CurrencyDetail

   fileprivate let memory: MemoryCache<GetCurrencyDetailRequest, CurrencyDetailData>
   fileprivate let cache: BasicCache<GetCurrencyDetailRequest, CurrencyDetailData>
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<CurrencyDetailData, CurrencyDetail>

   init(apiClient: APIClient, storage: CurrencyDetailStorage) {
      entityTransformer = DomainTransformer.currencyDetail()
      let routerTransformer = RouterTransformer.currencyDetail()
      let jsonTransformer = JsonTransformer.currencyDetail()
      memory = MemoryCache<GetCurrencyDetailRequest, CurrencyDetailData>()
      let network = NetworkDataSource(apiClient: apiClient,
                                      keyTransformer: routerTransformer,
                                      valueTransformer: jsonTransformer)

      cache = CacheFactory.orchestratedVolatileCache(memory: memory,
                                                     disk: storage,
                                                     network: network,
                                                     expiry: 15)
   }
}

extension CurrencyDetailRepository {
   func get(_ key: GetCurrencyDetailRequest) -> Observable<CurrencyDetail> {
      return cache.get(key)
         .flatMap(entityTransformer.transform)
   }
}
