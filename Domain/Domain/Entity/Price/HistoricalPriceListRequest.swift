//
//  HistoricalPriceListRequest.swift
//  Domain
//
//  Created by Li Hao Lai on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct HistoricalPriceListRequest: RequestType {
   public let fromSymbol: Currency
   public let toSymbol: Currency
   public let exchange: Exchange
   public let aggregate: Int
   public let limit: Int
   public let routerType: PriceHistoRouterType

   public var primaryKey: String {
      return "\(fromSymbol.symbol)_\(toSymbol.symbol)_\(exchange.name)_\(aggregate)_\(limit)_\(routerType.url)"
   }

   public init(fromSymbol: Currency, toSymbol: Currency, exchange: Exchange,
               aggregate: Int, limit: Int, routerType: PriceHistoRouterType) {
      self.fromSymbol = fromSymbol
      self.toSymbol = toSymbol
      self.exchange = exchange
      self.aggregate = aggregate
      self.limit = limit
      self.routerType = routerType
   }

   public static func createEmpty() -> HistoricalPriceListRequest {
      // Neglible value
      return HistoricalPriceListRequest(fromSymbol: Currency(id: "BTC", name: "Bitcoin", symbol: "BTC"),
                                        toSymbol: Currency(id: "ETH", name: "Ethereum", symbol: "ETH"),
                                        exchange: Exchange(id: "Gemini", name: "Gemini"),
                                        aggregate: 0,
                                        limit: 0,
                                        routerType: .minute)
   }
}
