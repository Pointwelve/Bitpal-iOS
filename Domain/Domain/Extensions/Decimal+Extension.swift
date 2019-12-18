//
//  Decimal+Extension.swift
//  Domain
//
//  Created by James Lai on 23/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

extension Decimal {
   public var doubleValue: Double {
      return NSDecimalNumber(decimal: self).doubleValue
   }
}
