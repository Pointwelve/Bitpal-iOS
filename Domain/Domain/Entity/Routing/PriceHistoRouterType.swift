//
//  PriceHistoRouterType.swift
//  Domain
//
//  Created by Kok Hong Choo on 23/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
public enum PriceHistoRouterType {
   case minute
   case hour
   case day

   public var url: String {
      switch self {
      case .minute:
         return "/data/histominute"
      case .hour:
         return "/data/histohour"
      case .day:
         return "/data/histoday"
      }
   }
}
