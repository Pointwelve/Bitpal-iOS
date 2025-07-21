//
//  PriceItem.swift
//  Domain
//
//  Created by Hong on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct CurrencyPair: DomainType, Equatable, Hashable {
   public let baseCurrency: Currency
   public let quoteCurrency: Currency
   public let exchange: Exchange
   public let price: Double

   public var reciprocalPrice: Double {
      return price == 0 ? 0 : 1 / price
   }

   public var debugDescription: String {
      return "\(baseCurrency.name):\(quoteCurrency.name) \(String(format: "%\(8)f", price))"
   }

   public func flipped() -> CurrencyPair {
      return CurrencyPair(baseCurrency: quoteCurrency,
                          quoteCurrency: baseCurrency,
                          exchange: exchange,
                          price: reciprocalPrice)
   }

   public var primaryKey: String {
      return "\(baseCurrency.name)\(quoteCurrency.name)\(exchange.name)"
   }

   public init(baseCurrency: Currency, quoteCurrency: Currency, exchange: Exchange, price: Double) {
      self.baseCurrency = baseCurrency
      self.quoteCurrency = quoteCurrency
      self.exchange = exchange
      self.price = price
   }
}
