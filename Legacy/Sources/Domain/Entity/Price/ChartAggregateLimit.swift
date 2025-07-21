//
//  ChartAggregateLimit.swift
//  App
//
//  Created by Hong on 22/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum ChartAggregateMinute: Int {
   case one = 1
   case five = 5
   case fifteen = 15
   case thirty = 30
   case sixty = 60

   public var minutePerHour: Int {
      return 60 / rawValue
   }

   public func limitHour(limit: ChartLimitHour) -> Int {
      return minutePerHour * limit.rawValue
   }
}

public enum ChartLimitHour: Int {
   case twentyFour = 24
   case twelve = 12
   case eight = 8
   case four = 4
   case one = 1
}
