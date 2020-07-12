//
//  RealmConvertible.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RealmSwift

protocol RealmConvertible {
   associatedtype RealmObject: Object

   /// Converts object from `Data` to `Realm` layer.
   func asRealm() -> RealmObject
}
