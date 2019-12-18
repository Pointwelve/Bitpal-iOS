//
//  TestableInvalidatedRealmObject.swift
//  Data
//
//  Created by Ryne Cheow on 25/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RealmSwift

class TestableInvalidatedRealmObject: Object {
   @objc dynamic var id = ""
   @objc dynamic var value = 0

   override static func primaryKey() -> String {
      return "id"
   }
}
