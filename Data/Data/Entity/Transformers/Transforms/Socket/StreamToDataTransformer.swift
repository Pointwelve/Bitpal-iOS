//
//  StreamToDataTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 18/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension StreamPriceData: StreamDeserializable {
   /// response format: '{Type}~{ExchangeName}~{FromCurrency}~{ToCurrency}~{Flag}
   /// ~{Price}~{LastUpdate}~{LastVolume}~{LastVolumeTo}~{LastTradeId}~{Volume24h}~{Volume24hTo}~{MaskInt}'

   private enum Separator: String {
      case tilda = "~"
   }

   init(streamData: String) throws {
      let data = streamData.components(separatedBy: Separator.tilda.rawValue)

      guard let mask = data.last,
         let maskInt = Int(mask, radix: 16) else {
         throw ParseError.parseFailed
      }

      guard data.count >= 5 else {
         throw ParseError.parseFailed
      }

      var dictionary: [StreamPriceKey: String] = [
         .type: data[0],
         .exchange: data[1],
         .baseCurrency: data[2],
         .quoteCurrency: data[3],
         .priceChange: data[4]
      ]

      var count = 5
      for key in StreamPriceKey.fields.dropFirst(5)
         where data[safe: count] != nil && (maskInt & key.bitRepresentation != 0) {
         dictionary[key] = data[count]
         count += 1
      }

      guard let typeStr = dictionary[.type], let type = Int(typeStr),
         let exchange = dictionary[.exchange],
         let baseCurrency = dictionary[.baseCurrency],
         let quoteCurrency = dictionary[.quoteCurrency],
         let priceChangeStr = dictionary[.priceChange], let priceChange = Int(priceChangeStr) else {
         throw ParseError.parseFailed
      }

      self.type = type
      self.exchange = exchange
      self.baseCurrency = baseCurrency
      self.quoteCurrency = quoteCurrency
      self.priceChange = priceChange
      price = Double(dictionary[.price] ?? "") // failable
      bid = Double(dictionary[.bid] ?? "") // failable
      offer = Double(dictionary[.offer] ?? "") // failable
      lastUpdateTimeStamp = Int(dictionary[.lastUpdate] ?? "") // failable
      avg = Double(dictionary[.avg] ?? "") // failable
      lastVolume = Double(dictionary[.lastVolume] ?? "") // failable
      lastVolumeTo = Double(dictionary[.lastVolumeTo] ?? "") // failable
      lastTradeId = Int(dictionary[.lastTradeId] ?? "") // failable
      volumeHour = Double(dictionary[.volumeHour] ?? "") // failable
      volumeHourTo = Double(dictionary[.volumeHourTo] ?? "") // failable
      volume24h = Double(dictionary[.volume24Hour] ?? "") // failable
      volume24hTo = Double(dictionary[.volume24HourTo] ?? "") // failable
      openHour = Double(dictionary[.openHour] ?? "") // failable
      highHour = Double(dictionary[.highHour] ?? "") // failable
      lowHour = Double(dictionary[.lowHour] ?? "") // failable
      open24Hour = Double(dictionary[.open24Hour] ?? "") // failable
      high24Hour = Double(dictionary[.high24Hour] ?? "") // failable
      low24Hour = Double(dictionary[.low24Hour] ?? "") // failable
      lastMarket = Double(dictionary[.lastMarket] ?? "") // failable

      self.mask = mask
   }
}
