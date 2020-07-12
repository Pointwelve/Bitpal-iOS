//
//  CryptoCurrency.swift
//  App
//
//  Created by Li Hao Lai on 19/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

@objc final class CryptoCurrency: NSObject {
   @objc dynamic var type: PriceStreamType = .trade
   @objc dynamic var exchange: String = ""
   @objc dynamic var baseCurrency: String = ""
   @objc dynamic var quoteCurrency: String = ""
   @objc dynamic var priceChange: PriceChange = .unchanged
   @objc dynamic var price: Double = 0
   @objc dynamic var bid: Double = 0
   @objc dynamic var offer: Double = 0
   @objc dynamic var lastUpdateTimeStamp: Int = 0
   @objc dynamic var avg: Double = 0
   @objc dynamic var lastVolume: Double = 0
   @objc dynamic var lastVolumeTo: Double = 0
   @objc dynamic var lastTradeId: Int = 0
   @objc dynamic var volumeHour: Double = 0
   @objc dynamic var volumeHourTo: Double = 0
   @objc dynamic var volume24h: Double = 0
   @objc dynamic var volume24hTo: Double = 0
   @objc dynamic var openHour: Double = 0
   @objc dynamic var highHour: Double = 0
   @objc dynamic var lowHour: Double = 0
   @objc dynamic var open24Hour: Double = 0
   @objc dynamic var high24Hour: Double = 0
   @objc dynamic var low24Hour: Double = 0
   @objc dynamic var lastMarket: Double = 0
   @objc dynamic var mask: String = ""

   init(baseCurrency: Currency, quoteCurrency: Currency) {
      self.baseCurrency = baseCurrency.symbol
      self.quoteCurrency = quoteCurrency.symbol
      super.init()
   }

   init(streamPrice: StreamPrice) {
      type = streamPrice.type
      exchange = streamPrice.exchange.name
      baseCurrency = streamPrice.baseCurrency.symbol
      quoteCurrency = streamPrice.quoteCurrency.symbol
      priceChange = streamPrice.priceChange
      price = streamPrice.price ?? 0
      bid = streamPrice.bid ?? 0
      offer = streamPrice.offer ?? 0
      lastUpdateTimeStamp = streamPrice.lastUpdateTimeStamp ?? 0
      avg = streamPrice.avg ?? 0
      lastVolume = streamPrice.lastVolume ?? 0
      lastVolumeTo = streamPrice.lastVolumeTo ?? 0
      lastTradeId = streamPrice.lastTradeId ?? 0
      volumeHour = streamPrice.volumeHour ?? 0
      volumeHourTo = streamPrice.volumeHourTo ?? 0
      volume24h = streamPrice.volume24h ?? 0
      volume24hTo = streamPrice.volume24hTo ?? 0
      openHour = streamPrice.openHour ?? 0
      highHour = streamPrice.highHour ?? 0
      lowHour = streamPrice.lowHour ?? 0
      open24Hour = streamPrice.open24Hour ?? 0
      high24Hour = streamPrice.high24Hour ?? 0
      low24Hour = streamPrice.low24Hour ?? 0
      lastMarket = streamPrice.lastMarket ?? 0
      mask = streamPrice.mask
      super.init()
   }

   // swiftlint:disable cyclomatic_complexity
   func update(with streamPrice: StreamPrice) {
      type = streamPrice.type
      exchange = streamPrice.exchange.name
      priceChange = streamPrice.priceChange

      if let price = streamPrice.price {
         self.price = price
      }

      if let bid = streamPrice.bid {
         self.bid = bid
      }

      if let offer = streamPrice.offer {
         self.offer = offer
      }

      if let lastUpdateTimeStamp = streamPrice.lastUpdateTimeStamp {
         self.lastUpdateTimeStamp = lastUpdateTimeStamp
      }

      if let avg = streamPrice.avg {
         self.avg = avg
      }

      if let lastVolume = streamPrice.lastVolume {
         self.lastVolume = lastVolume
      }

      if let lastVolumeTo = streamPrice.lastVolumeTo {
         self.lastVolumeTo = lastVolumeTo
      }

      if let lastTradeId = streamPrice.lastTradeId {
         self.lastTradeId = lastTradeId
      }

      if let volumeHour = streamPrice.volumeHour {
         self.volumeHour = volumeHour
      }

      if let volumeHourTo = streamPrice.volumeHourTo {
         self.volumeHourTo = volumeHourTo
      }

      if let volume24h = streamPrice.volume24h {
         self.volume24h = volume24h
      }

      if let volume24hTo = streamPrice.volume24hTo {
         self.volume24hTo = volume24hTo
      }

      if let openHour = streamPrice.openHour {
         self.openHour = openHour
      }

      if let highHour = streamPrice.highHour {
         self.highHour = highHour
      }

      if let lowHour = streamPrice.lowHour {
         self.lowHour = lowHour
      }

      if let open24Hour = streamPrice.open24Hour {
         self.open24Hour = open24Hour
      }

      if let high24Hour = streamPrice.high24Hour {
         self.high24Hour = high24Hour
      }

      if let low24Hour = streamPrice.low24Hour {
         self.low24Hour = low24Hour
      }

      if let lastMarket = streamPrice.lastMarket {
         self.lastMarket = lastMarket
      }

      mask = streamPrice.mask
   }
}
