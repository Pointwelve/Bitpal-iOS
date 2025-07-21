//
//  Watchlist.swift
//  Domain
//
//  Created by Hong on 29/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct Watchlist: DomainType, Equatable {
   public let id: String
   public let currencyPairs: [CurrencyPair]
   public let modifyDate: Date

   public init(id: String = defaultKey, currencyPairs: [CurrencyPair], modifyDate: Date) {
      self.id = id
      self.currencyPairs = currencyPairs
      self.modifyDate = modifyDate
   }

   public static let defaultKey = "WatchListId"
}
