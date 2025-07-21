//
//  CurrencyPairRealm.swift
//  Data
//
//  Created by Hong on 25/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RealmSwift

@objc final class CurrencyPairGroupRealm: Object {
   @objc dynamic var id = ""
   @objc dynamic var baseCurrency: CurrencyRealm?
   @objc dynamic var quoteCurrency: CurrencyRealm?
   var exchanges = List<ExchangeRealm>()

   override static func primaryKey() -> String? {
      return "id"
   }
}
