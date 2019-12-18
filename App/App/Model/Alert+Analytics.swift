//
//  Alert+Analytics.swift
//  App
//
//  Created by Ryne Cheow on 7/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain

extension Alert {
   fileprivate enum Key: String {
      case qualifiedPair = "Qualified Pair"
      case currencyPair = "Currency Pair"
      case baseCurrency = "Base Currency"
      case quoteCurrency = "Quote Currency"
      case exchange = "Exchange"
      case referencePrice = "Reference Price"
   }

   var analyticsMetadata: [String: Any] {
      return [
         Key.qualifiedPair.rawValue: "\(exchange)_\(pair)",
         Key.currencyPair.rawValue: "\(base)\(quote)",
         Key.baseCurrency.rawValue: base,
         Key.quoteCurrency.rawValue: quote,
         Key.exchange.rawValue: exchange
      ]
   }
}

extension CreateAlertRequest {
   fileprivate enum Key: String {
      case qualifiedPair = "Qualified Pair"
      case currencyPair = "Currency Pair"
      case baseCurrency = "Base Currency"
      case quoteCurrency = "Quote Currency"
      case exchange = "Exchange"
      case referencePrice = "Reference Price"
   }

   var analyticsMetadata: [String: Any] {
      return [
         Key.qualifiedPair.rawValue: "\(exchange)_\(pair)",
         Key.currencyPair.rawValue: "\(base)\(quote)",
         Key.baseCurrency.rawValue: base,
         Key.quoteCurrency.rawValue: quote,
         Key.exchange.rawValue: exchange
      ]
   }
}
