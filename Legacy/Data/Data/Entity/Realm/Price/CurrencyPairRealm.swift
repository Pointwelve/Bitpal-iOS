//
//  CurrencyPairRealm.swift
//  Data
//
//  Created by Ryne Cheow on 12/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RealmSwift

@objc final class CurrencyPairRealm: Object {
   @objc dynamic var id = ""
   @objc dynamic var baseCurrency: CurrencyRealm?
   @objc dynamic var quoteCurrency: CurrencyRealm?
   @objc dynamic var exchange: ExchangeRealm?

   override static func primaryKey() -> String? {
      return "id"
   }
}
