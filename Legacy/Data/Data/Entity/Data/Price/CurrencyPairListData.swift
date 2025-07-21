//
//  CurrencyPairListData.swift
//  Data
//
//  Created by Hong on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct CurrencyPairListData: DataType, Equatable, Modifiable {
   let id: String
   let currencyPairs: [CurrencyPairGroupData]
   var modifyDate: Date

   init(id: String,
        currencyPairs: [CurrencyPairGroupData],
        modifyDate: Date) {
      self.modifyDate = modifyDate
      self.id = id
      self.currencyPairs = currencyPairs
   }
}
