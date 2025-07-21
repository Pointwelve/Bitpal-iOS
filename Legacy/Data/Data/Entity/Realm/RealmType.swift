//
//  RealmType.swift
//  Data
//
//  Created by Ryne Cheow on 2/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

@objc protocol RealmType {}

extension Object: RealmType {}
