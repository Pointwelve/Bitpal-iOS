//
//  HistoricalPriceListRepository.swift
//  Data
//
//  Created by Li Hao Lai on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias HistoricalPriceListRepositoryType = Gettable

class HistoricalPriceListRepository: HistoricalPriceListRepositoryType {
   typealias Key = HistoricalPriceListRequest
   typealias Value = HistoricalPriceList

   fileprivate let memory: MemoryCache<HistoricalPriceListRequest, HistoricalPriceListData>
   fileprivate let cache: BasicCache<HistoricalPriceListRequest, HistoricalPriceListData>
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<HistoricalPriceListData, HistoricalPriceList>

   init(apiClient: APIClient, storage: HistoricalPriceListStorage, currenciesStorage: CurrenciesStorage) {
      let currencyRetrieval: (String) -> Observable<CurrencyData> = {
         currenciesStorage.get($0)
      }
      entityTransformer = DomainTransformer.historicalPriceList(using: currencyRetrieval)
      let routerTransformer = RouterTransformer.historicalPriceList()
      let jsonTransformer = JsonTransformer.historicalPrice()
      memory = MemoryCache<HistoricalPriceListRequest, HistoricalPriceListData>()
      let network = NetworkDataSource(apiClient: apiClient,
                                      keyTransformer: routerTransformer,
                                      valueTransformer: jsonTransformer)

      cache = CacheFactory.orchestratedVolatileCache(memory: memory,
                                                     disk: storage,
                                                     network: network,
                                                     expiry: 60 * 5)
   }
}

extension HistoricalPriceListRepository {
   func get(_ key: HistoricalPriceListRequest) -> Observable<HistoricalPriceList> {
      return cache
         .get(key)
         .flatMap(entityTransformer.transform)
   }
}
