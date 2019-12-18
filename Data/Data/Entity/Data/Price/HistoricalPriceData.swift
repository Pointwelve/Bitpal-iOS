//
//  HistoricalPriceData.swift
//  Data
//
//  Created by Li Hao Lai on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

struct HistoricalPriceData: DataType, Equatable {
   let time: Int
   let open: Double
   let high: Double
   let low: Double
   let close: Double
   let volumeFrom: Double
   let volumeTo: Double
}
