//
//  StreamPriceKey.swift
//  Data
//
//  Created by Li Hao Lai on 18/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

enum StreamPriceKey: String {
   case type
   case exchange
   case baseCurrency
   case quoteCurrency
   case priceChange
   case price
   case bid
   case offer
   case lastUpdate
   case avg
   case lastVolume
   case lastVolumeTo
   case lastTradeId
   case volumeHour
   case volumeHourTo
   case volume24Hour
   case volume24HourTo
   case openHour
   case highHour
   case lowHour
   case open24Hour
   case high24Hour
   case low24Hour
   case lastMarket

   var bitRepresentation: Int {
      switch self {
      case .type, .exchange, .baseCurrency, .quoteCurrency, .priceChange:
         return 0

      case .price:
         return 1 << 0

      case .bid:
         return 1 << 1

      case .offer:
         return 1 << 2

      case .lastUpdate:
         return 1 << 3

      case .avg:
         return 1 << 4

      case .lastVolume:
         return 1 << 5

      case .lastVolumeTo:
         return 1 << 6

      case .lastTradeId:
         return 1 << 7

      case .volumeHour:
         return 1 << 8

      case .volumeHourTo:
         return 1 << 9

      case .volume24Hour:
         return 1 << 10

      case .volume24HourTo:
         return 1 << 11

      case .openHour:
         return 1 << 12

      case .highHour:
         return 1 << 13

      case .lowHour:
         return 1 << 14

      case .open24Hour:
         return 1 << 15

      case .high24Hour:
         return 1 << 16

      case .low24Hour:
         return 1 << 17

      case .lastMarket:
         return 1 << 18
      }
   }

   static let fields = [
      type, exchange, baseCurrency, quoteCurrency, priceChange,
      price, bid, offer, lastUpdate, avg, lastVolume, lastVolumeTo,
      lastTradeId, volumeHour, volumeHourTo, volume24Hour, volume24HourTo,
      openHour, highHour, lowHour, open24Hour, high24Hour,
      low24Hour, lastMarket
   ]
}
