//
//  HistroyPrice.swift
//  Domain
//
//  Created by Li Hao Lai on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct HistoricalPrice: DomainType, Equatable {
   public let time: Int
   public let open: Double
   public let high: Double
   public let low: Double
   public let close: Double
   public let volumeFrom: Double
   public let volumeTo: Double

   public init(time: Int, open: Double, high: Double, low: Double,
               close: Double, volumeFrom: Double, volumeTo: Double) {
      self.time = time
      self.open = open
      self.high = high
      self.low = low
      self.close = close
      self.volumeFrom = volumeFrom
      self.volumeTo = volumeTo
   }
}
