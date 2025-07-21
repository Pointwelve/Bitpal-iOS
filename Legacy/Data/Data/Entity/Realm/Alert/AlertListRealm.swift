//
//  AlertListRealm.swift
//  Data
//
//  Created by James Lai on 23/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RealmSwift

@objc final class AlertListRealm: Object, Modifiable {
   @objc dynamic var modifyDate = Date()
   @objc dynamic var id = AlertList.defaultKey
   var alerts = List<AlertRealm>()

   override static func primaryKey() -> String? {
      return "id"
   }
}
