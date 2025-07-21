//
//  RealmCascadeDeletable.swift
//  Data
//
//  Created by Ryne Cheow on 2/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RealmSwift

protocol RealmCascadeDeletable {
   func cascadeDeleteObjects() -> [Object]
}
