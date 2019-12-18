//
//  TestableRealmObject.swift
//  Data
//
//  Created by Ryne Cheow on 13/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Foundation
import RealmSwift

final class TestableRealmObject: Object {
   @objc dynamic var id = ""
   @objc dynamic var value = 0

   override static func primaryKey() -> String {
      return "id"
   }
}

final class TestableRealmConvertible: DataType {
   let value: Int

   init(value: Int) {
      self.value = value
   }
}

extension TestableRealmConvertible: RealmConvertible {
   typealias RealmObject = TestableRealmObject

   func asRealm() -> TestableRealmObject {
      let object = TestableRealmObject()
      object.value = value

      return object
   }
}
