//
//  CurrencyRealm.swift
//  Data
//
//  Created by Li Hao Lai on 21/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RealmSwift

@objc final class CurrencyRealm: Object {
   @objc dynamic var id: String = ""
   @objc dynamic var name: String = ""
   @objc dynamic var symbol: String = ""

   override static func primaryKey() -> String? {
      return "id"
   }
}
