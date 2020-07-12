//
//  PriceChange.swift
//  App
//
//  Created by Hong on 14/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import UIKit

extension PriceChange {
   var color: UIColor {
      switch self {
      case .up:
         return Color.PriceChange.positive
      case .down:
         return Color.PriceChange.negative
      case .unchanged:
         return Color.warmGrey
      }
   }
}
