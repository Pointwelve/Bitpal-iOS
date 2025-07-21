//
//  DomainToDataTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension Configuration: DataConvertible {
   typealias DataType = ConfigurationData

   func asData() -> DataType {
      return .init(apiHost: apiHost,
                   functionsHost: functionsHost,
                   socketHost: socketHost,
                   sslCertificateData: sslCertificateData,
                   companyName: companyName,
                   apiKey: apiKey,
                   termsAndConditions: termsAndConditions)
   }
}

extension Preferences: DataConvertible {
   typealias DataType = PreferencesData

   /// Convert from `Preferences` in `Domain` layer to `PreferencesData` in `Data` layer.
   func asData() -> DataType {
      // swiftlint:disable identifier_name
      let _language = language?.asData()
      let _theme = theme?.asData()

      return .init(language: _language,
                   theme: _theme,
                   databaseName: databaseName,
                   installed: installed,
                   chartType: chartType?.rawValue)
   }
}

extension Language: DataConvertible {
   typealias DataType = LanguageData

   func asData() -> DataType {
      // swiftlint:disable force_try
      return try! .init(code: rawValue)
   }
}

extension Theme: DataConvertible {
   typealias DataType = ThemeData

   func asData() -> DataType {
      return try! .init(name: rawValue)
   }
}

extension CurrencyPair: DataConvertible {
   typealias DataType = CurrencyPairData

   func asData() -> DataType {
      return .init(baseCurrency: baseCurrency.asData(),
                   quoteCurrency: quoteCurrency.asData(),
                   exchange: exchange.asData(),
                   price: price)
   }
}

extension CurrencyPairList: DataConvertible {
   typealias DataType = CurrencyPairListData

   func asData() -> DataType {
      return .init(id: id,
                   currencyPairs: currencyPairs.asData(),
                   modifyDate: modifyDate)
   }
}

extension CurrencyPairGroup: DataConvertible {
   typealias DataType = CurrencyPairGroupData

   func asData() -> CurrencyPairGroupData {
      return .init(id: id,
                   baseCurrency: baseCurrency.asData(),
                   quoteCurrency: quoteCurrency.asData(),
                   exchanges: exchanges.asData())
   }
}

extension StreamPrice: DataConvertible {
   typealias DataType = StreamPriceData

   func asData() -> DataType {
      return .init(type: type.rawValue,
                   exchange: exchange.name,
                   baseCurrency: baseCurrency.symbol,
                   quoteCurrency: quoteCurrency.symbol,
                   priceChange: priceChange.rawValue,
                   price: price, bid: bid, offer: offer,
                   lastUpdateTimeStamp: lastUpdateTimeStamp, avg: avg,
                   lastVolume: lastVolume, lastVolumeTo: lastVolumeTo,
                   lastTradeId: lastTradeId, volumeHour: volumeHour,
                   volumeHourTo: volumeHourTo, volume24h: volume24h,
                   volume24hTo: volume24hTo, openHour: openHour,
                   highHour: highHour, lowHour: lowHour, open24Hour: open24Hour,
                   high24Hour: high24Hour, low24Hour: low24Hour, lastMarket: lastMarket,
                   mask: mask)
   }
}

extension HistoricalPrice: DataConvertible {
   typealias DataType = HistoricalPriceData

   func asData() -> DataType {
      return .init(time: time, open: open, high: high, low: low,
                   close: close, volumeFrom: volumeFrom, volumeTo: volumeTo)
   }
}

extension HistoricalPriceList: DataConvertible {
   typealias DataType = HistoricalPriceListData

   func asData() -> DataType {
      return .init(baseCurrency: baseCurrency.symbol,
                   quoteCurrency: quoteCurrency.symbol,
                   exchange: exchange.name,
                   historicalPrices: historicalPrices.asData(),
                   modifyDate: modifyDate)
   }
}

extension Watchlist: DataConvertible {
   typealias DataType = WatchlistData

   func asData() -> DataType {
      return .init(id: id, currencyPairs: currencyPairs.asData(), modifyDate: modifyDate)
   }
}

extension CurrencyDetail: DataConvertible {
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

extension Currency: DataConvertible {
   typealias DataType = CurrencyData

   func asData() -> DataType {
      return .init(id: id, name: name, symbol: symbol)
   }
}

extension Exchange: DataConvertible {
   typealias DataType = ExchangeData

   func asData() -> DataType {
      return .init(id: id, name: name)
   }
}

extension AuthenticationToken: DataConvertible {
   typealias DataType = AuthenticationTokenData

   func asData() -> DataType {
      return .init(token: token)
   }
}

extension DeviceFingerprint: DataConvertible {
   typealias DataType = DeviceFingerprintData

   func asData() -> DataType {
      return .init(data: data)
   }
}

extension AnonymousMigrationResponse: DataConvertible {
   typealias DataType = AnonymousMigrationResponseData

   func asData() -> DataType {
      return .init(success: success,
                   numOfWatchlist: numOfWatchlist,
                   numOfPriceAlert: numOfPriceAlert)
   }
}

extension Alert: DataConvertible {
   typealias DataType = AlertData

   func asData() -> DataType {
      return .init(id: id,
                   base: base,
                   quote: quote,
                   exchange: exchange,
                   comparison: comparison,
                   reference: reference,
                   isEnabled: isEnabled)
   }
}

extension AlertList: DataConvertible {
   typealias DataType = AlertListData

   func asData() -> DataType {
      return .init(id: id, alerts: alerts.asData(), modifyDate: modifyDate)
   }
}

extension CreateAlertResponse: DataConvertible {
   typealias DataType = CreateAlertResponseData

   func asData() -> DataType {
      return .init(message: message, id: id)
   }
}
