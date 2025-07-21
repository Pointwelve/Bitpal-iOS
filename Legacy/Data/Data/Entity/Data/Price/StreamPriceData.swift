//
//  StreamPriceData.swift
//  Data
//
//  Created by Li Hao Lai on 7/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct StreamPriceData: DataType, Equatable {
   let type: Int
   let exchange: String
   let baseCurrency: String
   let quoteCurrency: String
   let priceChange: Int

   let price: Double?
   let bid: Double?
   let offer: Double?
   let lastUpdateTimeStamp: Int?
   let avg: Double?
   let lastVolume: Double?
   let lastVolumeTo: Double?
   let lastTradeId: Int?
   let volumeHour: Double?
   let volumeHourTo: Double?
   let volume24h: Double?
   let volume24hTo: Double?
   let openHour: Double?
   let highHour: Double?
   let lowHour: Double?
   let open24Hour: Double?
   let high24Hour: Double?
   let low24Hour: Double?
   let lastMarket: Double?

   let mask: String
}
