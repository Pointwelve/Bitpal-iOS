//
//  ChartPeriod.swift
//  Domain
//
//  Created by Kok Hong Choo on 23/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum ChartPeriod {
   case oneMinute
   case fiveMinute
   case fifteenMinutes
   case oneHour
   case fourHours
   case oneDay

   public static let allPeriods: [ChartPeriod] = [.oneMinute, .fiveMinute, .fifteenMinutes, .oneHour, .fourHours, .oneDay]

   var request: (Int, PriceHistoRouterType) {
      switch self {
      case .oneMinute:
         return (1, .minute)
      case .fiveMinute:
         return (5, .minute)
      case .fifteenMinutes:
         return (15, .minute)
      case .oneHour:
         return (1, .hour)
      case .fourHours:
         return (4, .hour)
      case .oneDay:
         return (1, .day)
      }
   }

   /// Total amount of data shown on screen
   var limit: Int {
      return 60
   }

   public func historicalRequest(from fromCurrency: Currency,
                                 toCurrency: Currency,
                                 exchange: Exchange) -> HistoricalPriceListRequest {
      return HistoricalPriceListRequest(fromSymbol: fromCurrency,
                                        toSymbol: toCurrency,
                                        exchange: exchange,
                                        aggregate: request.0,
                                        limit: limit,
                                        routerType: request.1)
   }
}
