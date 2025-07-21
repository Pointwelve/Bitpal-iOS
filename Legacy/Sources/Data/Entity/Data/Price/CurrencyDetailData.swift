//
//  CurrencyDetailData.swift
//  Data
//
//  Created by Kok Hong Choo on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct CurrencyDetailData: DataType, Equatable, Modifiable {
   let fromCurrency: String
   let toCurrency: String
   let price: Double
   let volume24Hour: Double
   let open24Hour: Double
   let high24Hour: Double
   let low24Hour: Double
   let change24Hour: Double
   let changePct24hour: Double
   let fromDisplaySymbol: String
   let toDisplaySymbol: String
   let marketCap: Double
   let exchange: String
   var modifyDate: Date

   var primaryKey: String {
      return "\(fromCurrency)\(toCurrency)\(exchange)"
   }
}
