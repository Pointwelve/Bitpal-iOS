//
//  WatchlistRepository.swift
//  Data
//
//  Created by Hong on 26/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias PeekWatchlistRepositoryType = Peekable

class PeekWatchlistRepository: PeekWatchlistRepositoryType {
   typealias Key = String
   typealias Value = Watchlist

   fileprivate let entityTransformer: BidirectionalValueTransformerBox<WatchlistData, Watchlist>
   fileprivate let cache: WatchlistStorage

   init(storage: WatchlistStorage) {
      entityTransformer = DomainTransformer.watchlist()
      cache = storage
   }
}

extension PeekWatchlistRepository {
   func peek() -> Observable<Watchlist> {
      return cache.get(Watchlist.defaultKey).flatMap(entityTransformer.transform)
   }
}
