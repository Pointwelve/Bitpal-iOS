//
//  HistoricalPriceListRealm.swift
//  Data
//
//  Created by Li Hao Lai on 16/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RealmSwift

@objc final class HistoricalPriceListRealm: Object {
   @objc dynamic var id = ""
   @objc dynamic var baseCurrency = ""
   @objc dynamic var quoteCurrency = ""
   @objc dynamic var exchange = ""
   @objc dynamic var modifyDate = Date()
   var historicalPrices = List<HistoricalPriceRealm>()

   override static func primaryKey() -> String? {
      return "id"
   }
}
