//
//  CurrencyPair+Extensions.swift
//  App
//
//  Created by Ryne Cheow on 2/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain

extension CurrencyPair {
   fileprivate enum Key: String {
      case qualifiedPair = "Qualified Pair"
      case currencyPair = "Currency Pair"
      case baseCurrency = "Base Currency"
      case quoteCurrency = "Quote Currency"
      case exchange = "Exchange"
   }

   var analyticsQualifiedPair: String {
      return "\(baseCurrency.symbol)/\(quoteCurrency.symbol)/\(exchange.name)"
   }

   var analyticsMetadata: [String: Any] {
      return [
         Key.qualifiedPair.rawValue: analyticsQualifiedPair,
         Key.currencyPair.rawValue: "\(baseCurrency.symbol)/\(quoteCurrency.symbol)",
         Key.baseCurrency.rawValue: baseCurrency.symbol,
         Key.quoteCurrency.rawValue: quoteCurrency.symbol,
         Key.exchange.rawValue: exchange.name
      ]
   }
}
