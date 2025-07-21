//
//  WatchlistFirebaseData.swift
//  Data
//
//  Created by Kok Hong Choo on 20/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//
import Domain
struct WatchlistFirebaseData: DataType, Equatable {
   private static let separator: Character = "_"
   private static let unknownCurrency: Substring = "unknown"

   let exchange: String
   let pair: String

   let baseCurrency: String

   let quoteCurrency: String

   init(currenyPair: CurrencyPair) {
      exchange = currenyPair.exchange.name
      pair = "\(currenyPair.baseCurrency.symbol)\(WatchlistFirebaseData.separator)\(currenyPair.quoteCurrency.symbol)"
      baseCurrency = currenyPair.baseCurrency.symbol
      quoteCurrency = currenyPair.quoteCurrency.symbol
   }

   init(exchange: String, pair: String) {
      self.exchange = exchange
      self.pair = pair
      let splitedPair = pair.split(separator: WatchlistFirebaseData.separator)
      baseCurrency = String(splitedPair.first ?? WatchlistFirebaseData.unknownCurrency)
      quoteCurrency = String(splitedPair.last ?? WatchlistFirebaseData.unknownCurrency)
   }
}
