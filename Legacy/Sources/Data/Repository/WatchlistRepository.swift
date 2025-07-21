//
//  WatchlistRepository.swift
//  Data
//
//  Created by Kok Hong Choo on 27/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias WatchlistRepositoryType = Readable & Peekable & Gettable

final class WatchlistRepository: WatchlistRepositoryType {
   typealias Key = SetWatchlistRequest
   typealias Value = Watchlist

   fileprivate let memory: MemoryCache<String, WatchlistData>
   fileprivate let getCache: BasicCache<String, WatchlistData>
   fileprivate let setCache: BasicCache<SetWatchlistRequest, WatchlistData>
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<WatchlistData, Watchlist>
   fileprivate let watchlistStorage: WatchlistStorage

   init(apiClient: APIClient, watchlistStorage: WatchlistStorage) {
      memory = MemoryCache<String, WatchlistData>()
      let routerTransformer = RouterTransformer.retrieveWatchlist()
      let jsonTransformer = JsonTransformer.getWatchlist()
      let network = NetworkDataSource(apiClient: apiClient,
                                      keyTransformer: routerTransformer,
                                      valueTransformer: jsonTransformer).asBasicCache()
      getCache = CacheFactory.orchestratedVolatileCache(memory: memory,
                                                        disk: watchlistStorage,
                                                        network: network,
                                                        expiry: 60 * 60 * 24,
                                                        maximumSize: 1)
      setCache = NetworkDataSource(apiClient: apiClient,
                                   keyTransformer: RouterTransformer.updateWatchlist(),
                                   valueTransformer: JsonTransformer.updateWatchlist()).asBasicCache()
      self.watchlistStorage = watchlistStorage
      entityTransformer = DomainTransformer.watchlist()
   }
}

extension WatchlistRepository {
   func read() -> Observable<Watchlist> {
      return getCache.get(Watchlist.defaultKey)
         .flatMap(entityTransformer.transform)
   }

   func peek() -> Observable<Watchlist> {
      return watchlistStorage.get(Watchlist.defaultKey)
         .flatMap(entityTransformer.transform)
   }

   func get(_ key: SetWatchlistRequest) -> Observable<Watchlist> {
      memory.clear()
      return setCache.get(key).flatMapLatest { data in
         self.watchlistStorage.set(data, for: Watchlist.defaultKey)
            .flatMapLatest { _ in
               Observable.just(data)
            }
      }.flatMap(entityTransformer.transform)
   }
}
