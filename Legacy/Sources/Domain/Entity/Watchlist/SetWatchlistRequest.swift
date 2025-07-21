//
//  SetWatchlistRequest.swift
//  Domain
//
//  Created by Kok Hong Choo on 20/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct SetWatchlistRequest: RequestType {
   public let currencyPairs: [CurrencyPair]

   public func hash(into hasher: inout Hasher) {
      hasher.combine(currencyPairs.reduce("") { $0 + $1.primaryKey })
   }

   public init(currencyPairs: [CurrencyPair]) {
      self.currencyPairs = currencyPairs
   }
}
