//
//  Appearable.swift
//  App
//
//  Created by Ryne Cheow on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol Appearable {
   func will(appear: Bool)
   func did(appear: Bool)
}

extension Appearable {
   func did(appear: Bool) {}
   func will(appear: Bool) {}
}
