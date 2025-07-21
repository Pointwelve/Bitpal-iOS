//
//  PriceStream.swift
//  Domain
//
//  Created by Li Hao Lai on 7/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

@objc
public enum PriceChange: Int {
   case up = 1
   case down = 2
   case unchanged = 4

   public static func priceChange(with percentage: Double) -> PriceChange {
      if percentage > 0 {
         return .up
      } else if percentage < 0 {
         return .down
      } else {
         return .unchanged
      }
   }
}
