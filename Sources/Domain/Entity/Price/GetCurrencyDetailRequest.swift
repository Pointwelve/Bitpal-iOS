//
//  GetCurrencyDetailRequest.swift
//  Domain
//
//  Created by Kok Hong Choo on 15/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct GetCurrencyDetailRequest: RequestType {
   public let currencyPair: CurrencyPair

   public var primaryKey: String {
      return currencyPair.primaryKey
   }

   public init(currencyPair: CurrencyPair) {
      self.currencyPair = currencyPair
   }

   public static func createEmpty() -> GetCurrencyDetailRequest {
      // Negligible value
      let currencyPair = CurrencyPair(baseCurrency: Currency(id: "BTC", name: "Bitcoin", symbol: "BTC"),
                                      quoteCurrency: Currency(id: "ETH", name: "Ethereum", symbol: "ETH"),
                                      exchange: Exchange(id: "Gemini", name: "Gemini"),
                                      price: 0.0)
      return .init(currencyPair: currencyPair)
   }
}
