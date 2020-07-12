//
//  WatchlistData.swift
//  Data
//
//  Created by Hong on 29/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct WatchlistData: DataType, Equatable, Modifiable {
   let id: String
   let currencyPairs: [CurrencyPairData]
   var modifyDate: Date
}
