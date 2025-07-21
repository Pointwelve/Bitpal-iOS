//
//  DataToRealmTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension HistoricalPriceData: RealmConvertible {
   typealias RealmObject = HistoricalPriceRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.time = time
      object.open = open
      object.high = high
      object.low = low
      object.close = close
      object.volumeFrom = volumeFrom
      object.volumeTo = volumeTo

      return object
   }
}

extension HistoricalPriceListData: RealmConvertible {
   typealias RealmObject = HistoricalPriceListRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = primaryKey
      object.baseCurrency = baseCurrency
      object.quoteCurrency = quoteCurrency
      object.exchange = exchange
      object.historicalPrices = historicalPrices.asRealmList()
      object.modifyDate = modifyDate

      return object
   }
}

extension CurrencyPairData: RealmConvertible {
   typealias RealmObject = CurrencyPairRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = primaryKey
      object.baseCurrency = baseCurrency.asRealm()
      object.quoteCurrency = quoteCurrency.asRealm()
      object.exchange = exchange.asRealm()
      return object
   }
}

extension WatchlistData: RealmConvertible {
   typealias RealmObject = WatchListRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.currencyPairs = currencyPairs.asRealmList()
      return object
   }
}

extension CurrencyPairListData: RealmConvertible {
   typealias RealmObject = CurrencyPairListRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = id
      object.currencyPairs = currencyPairs.asRealmList()

      return object
   }
}

extension CurrencyPairGroupData: RealmConvertible {
   typealias RealmObject = CurrencyPairGroupRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = id
      object.exchanges = exchanges.asRealmList()
      object.baseCurrency = baseCurrency.asRealm()
      object.quoteCurrency = quoteCurrency.asRealm()
      return object
   }
}

extension CurrencyData: RealmConvertible {
   typealias RealmObject = CurrencyRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = id
      object.name = name
      object.symbol = symbol
      return object
   }
}

extension ExchangeData: RealmConvertible {
   typealias RealmObject = ExchangeRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = name
      object.name = name
      return object
   }
}

extension CurrencyDetailData: RealmConvertible {
   typealias RealmObject = CurrencyDetailRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = primaryKey
      object.fromCurrency = fromCurrency
      object.toCurrency = toCurrency
      object.price = price
      object.volume24Hour = volume24Hour
      object.open24Hour = open24Hour
      object.high24Hour = high24Hour
      object.low24Hour = low24Hour
      object.change24Hour = change24Hour
      object.changePct24hour = changePct24hour
      object.fromDisplaySymbol = fromDisplaySymbol
      object.toDisplaySymbol = toDisplaySymbol
      object.marketCap = marketCap
      object.exchange = exchange
      return object
   }
}

extension AlertData: RealmConvertible {
   typealias RealmObject = AlertRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = id
      object.base = base
      object.quote = quote
      object.exchange = exchange
      object.comparison = comparison.rawValue
      object.reference = "\(reference)"
      object.isEnabled = isEnabled

      return object
   }
}

extension AlertListData: RealmConvertible {
   typealias RealmObject = AlertListRealm

   func asRealm() -> RealmObject {
      let object = RealmObject()
      object.id = id
      object.alerts = alerts.asRealmList()
      object.modifyDate = modifyDate

      return object
   }
}
