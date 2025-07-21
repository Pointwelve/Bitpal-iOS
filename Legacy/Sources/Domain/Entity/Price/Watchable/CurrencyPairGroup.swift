//
//  CurrencyPair.swift
//  Domain
//
//  Created by Ryne Cheow on 11/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct CurrencyPairGroup: DomainType, Equatable, Hashable {
   public let id: String
   public let baseCurrency: Currency
   public let quoteCurrency: Currency
   public let exchanges: [Exchange]

   public init(id: String, baseCurrency: Currency, quoteCurrency: Currency, exchanges: [Exchange]) {
      self.id = id
      self.baseCurrency = baseCurrency
      self.quoteCurrency = quoteCurrency
      self.exchanges = exchanges
   }

   public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
   }
}
