//
//  ChartPeriod.swift
//  App
//
//  Created by Kok Hong Choo on 21/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension ChartPeriod {
   var name: String {
      switch self {
      case .oneMinute:
         return "currency.detail.oneMinute".localized()
      case .fiveMinute:
         return "currency.detail.fiveMinute".localized()
      case .fifteenMinutes:
         return "currency.detail.fifteenMinutes".localized()
      case .oneHour:
         return "currency.detail.oneHour".localized()
      case .fourHours:
         return "currency.detail.fourHours".localized()
      case .oneDay:
         return "currency.detail.oneDay".localized()
      }
   }
}
