//
//  HistoricalPriceList.swift
//  Domain
//
//  Created by Li Hao Lai on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct HistoricalPriceList: DomainType {
   public let baseCurrency: Currency
   public let quoteCurrency: Currency
   public let exchange: Exchange
   public let historicalPrices: [HistoricalPrice]
   public let modifyDate: Date

   public init(baseCurrency: Currency, quoteCurrency: Currency,
               exchange: Exchange, historicalPrices: [HistoricalPrice], modifyDate: Date) {
      self.baseCurrency = baseCurrency
      self.quoteCurrency = quoteCurrency
      self.exchange = exchange
      self.historicalPrices = historicalPrices
      self.modifyDate = modifyDate
   }
}
