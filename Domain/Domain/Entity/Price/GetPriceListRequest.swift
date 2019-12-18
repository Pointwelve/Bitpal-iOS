//
//  GetPriceListRequest.swift
//  Domain
//
//  Created by Hong on 15/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct GetPriceListRequest: RequestType {
   public let currencyPairs: [CurrencyPair]
   public let streamType: PriceStreamType
   public var subscriptions: [String] {
      return currencyPairs.compactMap { currencyPair -> String in
         [
            "\(streamType.rawValue)",
            "\(currencyPair.exchange.name)",
            "\(currencyPair.baseCurrency.symbol)",
            "\(currencyPair.quoteCurrency.symbol)"
         ]
         .joined(separator: ParameterSeparator.tilda.rawValue)
      }
   }

   private enum ParameterSeparator: String {
      case tilda = "~"
   }

   public func hash(into hasher: inout Hasher) {
      hasher.combine(currencyPairs.reduce("") { "\($0)\($1.hashValue)," })
      hasher.combine(streamType)
   }

   public init(currencyPairs: [CurrencyPair], streamType: PriceStreamType = .current) {
      self.currencyPairs = currencyPairs
      self.streamType = streamType
   }
}
