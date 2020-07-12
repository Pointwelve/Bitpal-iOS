//
//  WatchlistDetailData.swift
//  App
//
//  Created by Kok Hong Choo on 16/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

enum WatchlistDetailData {
   case marketCap
   case volume24h
   case open24h
   case lowHigh24h

   var title: String {
      switch self {
      case .marketCap:
         return "currency.detail.marketCap".localized()
      case .volume24h:
         return "currency.detail.volume24h".localized()
      case .open24h:
         return "currency.detail.open24h".localized()
      case .lowHigh24h:
         return "currency.detail.lowHigh24h".localized()
      }
   }

   func getContent(_ currencyDetail: CurrencyDetail) -> String {
      switch self {
      case .marketCap:
         return "\(currencyDetail.toDisplaySymbol) \(currencyDetail.marketCap.formatUsingAbbrevation())"
      case .volume24h:
         return "\(currencyDetail.fromDisplaySymbol) \(currencyDetail.volume24Hour.formatUsingAbbrevation())"
      case .open24h:
         return "\(currencyDetail.toDisplaySymbol) \(currencyDetail.open24Hour.formatUsingSignificantDigits())"
      case .lowHigh24h:
         let low = currencyDetail.low24Hour.formatUsingSignificantDigits()
         let high = currencyDetail.high24Hour.formatUsingSignificantDigits()
         return "\(currencyDetail.toDisplaySymbol) \(low) / \(high)"
      }
   }

   static let defaultData: [WatchlistDetailData] = [.marketCap, .volume24h, .open24h, .lowHigh24h]
}
