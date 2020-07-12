//
//  HistoricalPriceRealm.swift
//  Data
//
//  Created by Li Hao Lai on 16/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RealmSwift

@objc final class HistoricalPriceRealm: Object {
   @objc dynamic var id = UUID().uuidString
   @objc dynamic var time = 0
   @objc dynamic var open = 0.0
   @objc dynamic var high = 0.0
   @objc dynamic var low = 0.0
   @objc dynamic var close = 0.0
   @objc dynamic var volumeFrom = 0.0
   @objc dynamic var volumeTo = 0.0
   override static func primaryKey() -> String? {
      return "id"
   }
}
