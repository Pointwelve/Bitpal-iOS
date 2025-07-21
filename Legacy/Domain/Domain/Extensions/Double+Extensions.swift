//
//  Double+Extensions.swift
//  Domain
//
//  Created by Li Hao Lai on 20/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

extension Double {
   public func priceChangeIn24HPct() -> PriceChange {
      let format = Double(Darwin.round(100 * self) / 100)
      return PriceChange.priceChange(with: format)
   }
}
