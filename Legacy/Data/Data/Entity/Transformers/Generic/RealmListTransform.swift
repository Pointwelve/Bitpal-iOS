//
//  RealmListTransform.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RealmSwift

extension Array where Element: Object {
   func asList() -> List<Element> {
      let list = List<Element>()
      forEach {
         list.append($0)
      }
      return list
   }
}

extension Array where Element: DataType & RealmConvertible {
   func asRealmList() -> List<Element.RealmObject> {
      let list = List<Element.RealmObject>()
      map { $0.asRealm() }.forEach {
         list.append($0)
      }
      return list
   }
}

extension RealmSwift.List {
   func asArray() -> [Element] {
      // Check if object was already invalidated or deleted by another operation
      // if so, there is nothing we can do with it at this juncture.
      if isInvalidated {
         return []
      }
      return Array(self)
   }
}

extension RealmSwift.List where Element == Object {
   func asArray() -> [Element] {
      // Check if object was already invalidated or deleted by another operation
      // if so, there is nothing we can do with it at this juncture.
      if isInvalidated {
         return []
      }
      return compactMap {
         $0.isInvalidated ? nil : $0
      }
   }

   func asTypeErasedArray() -> [Element] {
      return asArray().map {
         $0
      }
   }
}
