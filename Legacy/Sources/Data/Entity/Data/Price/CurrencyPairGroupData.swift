//
//  CurrencyPairData.swift
//  Data
//
//  Created by Ryne Cheow on 12/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct CurrencyPairGroupData: DataType, Equatable {
   let id: String
   let baseCurrency: CurrencyData
   let quoteCurrency: CurrencyData
   let exchanges: [ExchangeData]

   var primaryKey: String {
      return id
   }
}
