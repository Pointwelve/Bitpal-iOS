//
//  WatchlistDetailGraphType.swift
//  App
//
//  Created by Kok Hong Choo on 20/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import UIKit

extension ChartType {
   var image: UIImage {
      switch self {
      case .candlestick:
         return Image.candleStickIcon.resource
      case .line:
         return Image.lineChartIcon.resource
      }
   }

   var opposite: ChartType {
      switch self {
      case .candlestick:
         return .line
      case .line:
         return .candlestick
      }
   }
}
