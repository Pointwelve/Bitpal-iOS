//
//  CurrencyPairList.swift
//  Domain
//
//  Created by Hong on 15/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct CurrencyPairList: DomainType, Equatable {
   public let id: String
   public let currencyPairs: [CurrencyPairGroup]
   public let modifyDate: Date

   public init(id: String,
               currencyPairs: [CurrencyPairGroup],
               modifyDate: Date) {
      self.id = id
      self.currencyPairs = currencyPairs
      self.modifyDate = modifyDate
   }

   public var flattened: [CurrencyPair] {
      return currencyPairs.flatMap { pair in
         pair.exchanges.map { exchange in
            CurrencyPair(baseCurrency: pair.baseCurrency,
                         quoteCurrency: pair.quoteCurrency,
                         exchange: exchange, price: 0)
         }
      }
   }
}

public func ==(lhs: CurrencyPairList, rhs: CurrencyPairList) -> Bool {
   return lhs.id == rhs.id &&
      lhs.currencyPairs == rhs.currencyPairs
}
