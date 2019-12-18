//
//  CurrencyDetailRealm.swift
//  Data
//
//  Created by Kok Hong Choo on 27/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

@objc final class CurrencyDetailRealm: Object, Modifiable {
   @objc dynamic var modifyDate = Date()
   @objc dynamic var fromCurrency = ""
   @objc dynamic var toCurrency = ""
   @objc dynamic var price = 0.0
   @objc dynamic var volume24Hour = 0.0
   @objc dynamic var open24Hour = 0.0
   @objc dynamic var high24Hour = 0.0
   @objc dynamic var low24Hour = 0.0
   @objc dynamic var change24Hour = 0.0
   @objc dynamic var changePct24hour = 0.0
   @objc dynamic var fromDisplaySymbol = ""
   @objc dynamic var toDisplaySymbol = ""
   @objc dynamic var marketCap = 0.0
   @objc dynamic var exchange = ""
   @objc dynamic var id = ""

   override static func primaryKey() -> String? {
      return "id"
   }
}
