//
//  CurrencyPairData.swift
//  Data
//
//  Created by Hong on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct CurrencyPairData: DataType, Equatable {
   let baseCurrency: CurrencyData
   let quoteCurrency: CurrencyData
   let exchange: ExchangeData
   let price: Double

   var primaryKey: String {
      return "\(baseCurrency.symbol)\(quoteCurrency.symbol)\(exchange.name)"
   }
}
