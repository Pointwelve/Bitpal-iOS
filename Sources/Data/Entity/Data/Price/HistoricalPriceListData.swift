//
//  HistoricalPriceListData.swift
//  Data
//
//  Created by Li Hao Lai on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct HistoricalPriceListData: DataType, Equatable, Modifiable {
   let baseCurrency: String
   let quoteCurrency: String
   let exchange: String
   let historicalPrices: [HistoricalPriceData]
   var modifyDate: Date

   var primaryKey: String {
      return "\(baseCurrency)_\(quoteCurrency)_\(exchange)"
   }
}
