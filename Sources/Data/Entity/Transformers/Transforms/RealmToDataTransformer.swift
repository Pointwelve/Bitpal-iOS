//
//  RealmToDataTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension HistoricalPriceRealm: DataConvertible {
   typealias DataType = HistoricalPriceData

   func asData() -> DataType {
      return .init(time: time, open: open, high: high, low: low,
                   close: close, volumeFrom: volumeFrom, volumeTo: volumeTo)
   }
}

extension HistoricalPriceListRealm: DataConvertible {
   typealias DataType = HistoricalPriceListData

   func asData() -> DataType {
      return .init(baseCurrency: baseCurrency, quoteCurrency: quoteCurrency,
                   exchange: exchange, historicalPrices: historicalPrices.asData(), modifyDate: modifyDate)
   }
}

extension CurrencyPairRealm: DataConvertible {
   typealias DataType = CurrencyPairData

   func asData() -> DataType {
      return .init(baseCurrency: baseCurrency!.asData(),
                   quoteCurrency: quoteCurrency!.asData(),
                   exchange: exchange!.asData(),
                   price: 0.0)
   }
}

extension WatchListRealm: DataConvertible {
   typealias DataType = WatchlistData

   func asData() -> DataType {
      return .init(id: id,
                   currencyPairs: currencyPairs.map { $0.asData() },
                   modifyDate: modifyDate)
   }
}

extension CurrencyRealm: DataConvertible {
   typealias DataType = CurrencyData

   func asData() -> DataType {
      return .init(id: id, name: name, symbol: symbol)
   }
}

extension ExchangeRealm: DataConvertible {
   typealias DataType = ExchangeData

   func asData() -> DataType {
      return .init(id: id, name: name)
   }
}

extension CurrencyPairListRealm: DataConvertible {
   typealias DataType = CurrencyPairListData

   func asData() -> CurrencyPairListData {
      return .init(id: id,
                   currencyPairs: currencyPairs.asData(),
                   modifyDate: modifyDate)
   }
}

extension CurrencyPairGroupRealm: DataConvertible {
   typealias DataType = CurrencyPairGroupData

   func asData() -> DataType {
      return .init(id: id,
                   baseCurrency: baseCurrency!.asData(),
                   quoteCurrency: quoteCurrency!.asData(),
                   exchanges: exchanges.asData())
   }
}

extension CurrencyDetailRealm: DataConvertible {
   typealias DataType = CurrencyDetailData

   func asData() -> DataType {
      return .init(fromCurrency: fromCurrency, toCurrency: toCurrency, price: price,
                   volume24Hour: volume24Hour, open24Hour: open24Hour,
                   high24Hour: high24Hour, low24Hour: low24Hour, change24Hour: change24Hour,
                   changePct24hour: changePct24hour, fromDisplaySymbol: fromDisplaySymbol,
                   toDisplaySymbol: toDisplaySymbol, marketCap: marketCap,
                   exchange: exchange, modifyDate: modifyDate)
   }
}

extension AlertRealm: DataConvertible {
   typealias DataType = AlertData

   func asData() -> DataType {
      return .init(id: id,
                   base: base,
                   quote: quote,
                   exchange: exchange,
                   comparison: AlertComparison(rawValue: comparison)!,
                   reference: Decimal(string: reference)!,
                   isEnabled: isEnabled)
   }
}

extension AlertListRealm: DataConvertible {
   typealias DataType = AlertListData

   func asData() -> DataType {
      return .init(id: id, alerts: alerts.asData(), modifyDate: modifyDate)
   }
}
