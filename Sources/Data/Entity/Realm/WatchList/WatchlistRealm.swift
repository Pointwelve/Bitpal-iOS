//
//  WatchlistRealm.swift
//  Data
//
//  Created by Hong on 29/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

class WatchListRealm: Object, Modifiable {
   @objc dynamic var modifyDate = Date()
   @objc dynamic var id = Watchlist.defaultKey
   var currencyPairs = List<CurrencyPairRealm>()

   override static func primaryKey() -> String? {
      return "id"
   }
}
