//
//  StreamPrice.swift
//  Domain
//
//  Created by Li Hao Lai on 7/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct StreamPrice: DomainType, Equatable {
   public let type: PriceStreamType
   public let exchange: Exchange
   public let baseCurrency: Currency
   public let quoteCurrency: Currency
   public var priceChange: PriceChange
   public var price: Double?
   public var bid: Double?
   public var offer: Double?
   public var lastUpdateTimeStamp: Int?
   public var avg: Double?
   public var lastVolume: Double?
   public var lastVolumeTo: Double?
   public var lastTradeId: Int?
   public var volumeHour: Double?
   public var volumeHourTo: Double?
   public var volume24h: Double?
   public var volume24hTo: Double?
   public var openHour: Double?
   public var highHour: Double?
   public var lowHour: Double?
   public var open24Hour: Double?
   public var high24Hour: Double?
   public var low24Hour: Double?
   public var lastMarket: Double?
   public var mask: String

   public init(type: PriceStreamType, exchange: Exchange, baseCurrency: Currency,
               quoteCurrency: Currency, priceChange: PriceChange, price: Double?,
               bid: Double?, offer: Double?, lastUpdateTimeStamp: Int?, avg: Double?,
               lastVolume: Double?, lastVolumeTo: Double?, lastTradeId: Int?,
               volumeHour: Double?, volumeHourTo: Double?, volume24h: Double?,
               volume24hTo: Double?, openHour: Double?, highHour: Double?,
               lowHour: Double?, open24Hour: Double?, high24Hour: Double?,
               low24Hour: Double?, lastMarket: Double?, mask: String) {
      self.type = type
      self.exchange = exchange
      self.baseCurrency = baseCurrency
      self.quoteCurrency = quoteCurrency
      self.priceChange = priceChange
      self.price = price
      self.bid = bid
      self.offer = offer
      self.lastUpdateTimeStamp = lastUpdateTimeStamp
      self.avg = avg
      self.lastVolume = lastVolume
      self.lastVolumeTo = lastVolumeTo
      self.lastTradeId = lastTradeId
      self.volumeHour = volumeHour
      self.volumeHourTo = volumeHourTo
      self.volume24h = volume24h
      self.volume24hTo = volume24hTo
      self.openHour = openHour
      self.highHour = highHour
      self.lowHour = lowHour
      self.open24Hour = open24Hour
      self.high24Hour = high24Hour
      self.low24Hour = low24Hour
      self.lastMarket = lastMarket
      self.mask = mask
   }
}
