//
//  CurrencyPairRepository.swift
//  Data
//
//  Created by Li Hao on 29/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

typealias CurrencyPairRepositoryType = Gettable

class CurrencyPairRepository: CurrencyPairRepositoryType {
   typealias Key = String
   typealias Value = CurrencyPair

   fileprivate let entityTransformer: BidirectionalValueTransformerBox<CurrencyPairData, CurrencyPair>
   fileprivate let cache: CurrencyPairStorage

   init(storage: CurrencyPairStorage) {
      entityTransformer = DomainTransformer.currencyPair()
      cache = storage
   }
}

extension CurrencyPairRepository {
   func get(_ key: String) -> Observable<CurrencyPair> {
      return cache.get(key)
         .flatMap(entityTransformer.transform)
   }
}
