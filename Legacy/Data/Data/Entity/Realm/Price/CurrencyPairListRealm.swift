//
//  CurrenciesRealm.swift
//  Data
//
//  Created by James Lai on 17/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RealmSwift

@objc final class CurrencyPairListRealm: Object, Modifiable {
   @objc dynamic var modifyDate = Date()
   @objc dynamic var id = ""

   var currencyPairs = List<CurrencyPairGroupRealm>()

   override static func primaryKey() -> String? {
      return "id"
   }
}
