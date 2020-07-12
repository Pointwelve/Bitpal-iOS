//
//  AlertRealm.swift
//  Data
//
//  Created by James Lai on 23/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RealmSwift

@objc final class AlertRealm: Object {
   @objc dynamic var id = ""
   @objc dynamic var base = ""
   @objc dynamic var quote = ""
   @objc dynamic var exchange = ""
   @objc dynamic var comparison = ""
   @objc dynamic var reference = ""
   @objc dynamic var isEnabled = true
}
