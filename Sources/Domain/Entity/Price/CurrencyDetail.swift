//
//  CurrencyDetail.swift
//  Domain
//
//  Created by Kok Hong Choo on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct CurrencyDetail: DomainType, Equatable {
   public let fromCurrency: String
   public let toCurrency: String
   public let price: Double
   public let volume24Hour: Double
   public let open24Hour: Double
   public let high24Hour: Double
   public let low24Hour: Double
   public let change24Hour: Double
   public let changePct24hour: Double
   public let fromDisplaySymbol: String
   public let toDisplaySymbol: String
   public let marketCap: Double
   public let exchange: String
   public let modifyDate: Date

   public init(fromCurrency: String, toCurrency: String, price: Double,
               volume24Hour: Double, open24Hour: Double, high24Hour: Double, low24Hour: Double,
               change24Hour: Double, changePct24hour: Double, fromDisplaySymbol: String,
               toDisplaySymbol: String, marketCap: Double, exchange: String,
               modifyDate: Date) {
      self.fromCurrency = fromCurrency
      self.toCurrency = toCurrency
      self.price = price
      self.volume24Hour = volume24Hour
      self.open24Hour = open24Hour
      self.high24Hour = high24Hour
      self.low24Hour = low24Hour
      self.change24Hour = change24Hour
      self.changePct24hour = changePct24hour
      self.fromDisplaySymbol = fromDisplaySymbol
      self.toDisplaySymbol = toDisplaySymbol
      self.marketCap = marketCap
      self.exchange = exchange
      self.modifyDate = modifyDate
   }
}
