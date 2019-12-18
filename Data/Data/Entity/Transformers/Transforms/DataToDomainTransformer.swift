//
//  DataToDomainTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension ConfigurationData: DomainConvertible {
   typealias DomainType = Configuration

   func asDomain() -> DomainType {
      return .init(apiHost: apiHost,
                   functionsHost: functionsHost,
                   socketHost: socketHost,
                   sslCertificateData: sslCertificateData,
                   companyName: companyName,
                   termsAndConditions: termsAndConditions)
   }
}

extension PreferencesData: DomainConvertible {
   typealias DomainType = Preferences

   /// Convert from `PreferencesData` in `Data` layer to `Preferences` in `Domain` layer.
   func asDomain() -> DomainType {
      // swiftlint:disable identifier_name
      let _language = language?.asDomain()
      let _theme = theme?.asDomain()

      return .init(language: _language,
                   theme: _theme,
                   databaseName: databaseName,
                   installed: installed,
                   chartType: ChartType(rawValue: chartType ?? 0) ?? .line)
   }
}

extension LanguageData: DomainConvertible {
   typealias DomainType = Language

   func asDomain() -> DomainType {
      return .init(code: code)
   }
}

extension ThemeData: DomainConvertible {
   typealias DomainType = Theme

   func asDomain() -> DomainType {
      return .init(name: name)
   }
}

extension CurrencyPairData: DomainConvertible {
   typealias DomainType = CurrencyPair

   func asDomain() -> DomainType {
      return .init(baseCurrency: baseCurrency.asDomain(),
                   quoteCurrency: quoteCurrency.asDomain(),
                   exchange: exchange.asDomain(),
                   price: price)
   }
}

extension CurrencyPairListData: DomainConvertible {
   typealias DomainType = CurrencyPairList

   func asDomain() -> DomainType {
      return .init(id: id,
                   currencyPairs: currencyPairs.asDomain(),
                   modifyDate: modifyDate)
   }
}

extension CurrencyPairGroupData: DomainConvertible {
   typealias DomainType = CurrencyPairGroup

   func asDomain() -> DomainType {
      return .init(id: id,
                   baseCurrency: baseCurrency.asDomain(),
                   quoteCurrency: quoteCurrency.asDomain(),
                   exchanges: exchanges.asDomain())
   }
}

extension HistoricalPriceData: DomainConvertible {
   typealias DomainType = HistoricalPrice

   func asDomain() -> DomainType {
      return .init(time: time, open: open, high: high, low: low,
                   close: close, volumeFrom: volumeFrom, volumeTo: volumeTo)
   }
}

extension WatchlistData: DomainConvertible {
   typealias DomainType = Watchlist

   func asDomain() -> DomainType {
      return .init(id: id, currencyPairs: currencyPairs.asDomain(), modifyDate: modifyDate)
   }
}

extension CurrencyDetailData: DomainConvertible {
   typealias DomainType = CurrencyDetail

   func asDomain() -> DomainType {
      return .init(fromCurrency: fromCurrency, toCurrency: toCurrency, price: price,
                   volume24Hour: volume24Hour, open24Hour: open24Hour,
                   high24Hour: high24Hour, low24Hour: low24Hour, change24Hour: change24Hour,
                   changePct24hour: changePct24hour, fromDisplaySymbol: fromDisplaySymbol,
                   toDisplaySymbol: toDisplaySymbol, marketCap: marketCap,
                   exchange: exchange, modifyDate: modifyDate)
   }
}

extension CurrencyData: DomainConvertible {
   typealias DomainType = Currency

   func asDomain() -> DomainType {
      return .init(id: id, name: name, symbol: symbol)
   }
}

extension ExchangeData: DomainConvertible {
   typealias DomainType = Exchange

   func asDomain() -> DomainType {
      return .init(id: id, name: name)
   }
}

extension AuthenticationTokenData: DomainConvertible {
   typealias DomainType = AuthenticationToken

   func asDomain() -> DomainType {
      return .init(token: token)
   }
}

extension DeviceFingerprintData: DomainConvertible {
   typealias DomainType = DeviceFingerprint

   func asDomain() -> DomainType {
      return .init(data: data)
   }
}

extension AnonymousMigrationResponseData: DomainConvertible {
   typealias DomainType = AnonymousMigrationResponse

   func asDomain() -> DomainType {
      return .init(success: success,
                   numOfWatchlist: numOfWatchlist,
                   numOfPriceAlert: numOfPriceAlert)
   }
}

extension AlertData: DomainConvertible {
   typealias DomainType = Alert

   func asDomain() -> DomainType {
      return .init(id: id,
                   base: base,
                   quote: quote,
                   exchange: exchange,
                   comparison: comparison,
                   reference: reference,
                   isEnabled: isEnabled)
   }
}

extension AlertListData: DomainConvertible {
   typealias DomainType = AlertList

   func asDomain() -> DomainType {
      return .init(alerts: alerts.asDomain(), modifyDate: modifyDate)
   }
}

extension CreateAlertResponseData: DomainConvertible {
   typealias DomainType = CreateAlertResponse

   func asDomain() -> DomainType {
      return .init(message: message, id: id)
   }
}

extension StreamPriceData: DomainConvertible {
   typealias DomainType = StreamPrice
   func asDomain() -> DomainType {
      fatalError("Should not be called.")
   }
}

extension HistoricalPriceListData: DomainConvertible {
   typealias DomainType = HistoricalPriceList

   func asDomain() -> DomainType {
      fatalError("Should not be called.")
   }
}
