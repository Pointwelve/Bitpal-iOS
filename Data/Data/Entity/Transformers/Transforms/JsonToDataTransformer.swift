//
//  JsonToDataTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension CurrencyPairListData: JsonDeserializable {
   private enum Key: String {
      case currencyPairs
   }

   init(json: Any) throws {
      fatalError("init(json:) not implemented")
   }

   init(json: Any, id: String) throws {
      guard let json = json as? [[String: Any]] else {
         throw ParseError.parseFailed
      }

      currencyPairs = json.compactMap { try? CurrencyPairGroupData(json: $0) }
      modifyDate = Date()
      self.id = id
   }
}

extension CurrencyPairGroupData: JsonDeserializable {
   private enum Key: String {
      case id
      case base = "b"
      case quote = "q"
      case exchange = "e"
      case tokenizer = "_"
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let id = json[Key.id.rawValue] as? String,
         let exchangesDict = json[Key.exchange.rawValue] as? [String] else {
         throw ParseError.parseFailed
      }

      let symbols = id.split(separator: Character(Key.tokenizer.rawValue)).map { String($0) }

      guard let baseDict = json[Key.base.rawValue] as? [String: Any],
         let baseSymbol = symbols[safe: 0],
         let base = try? CurrencyData(json: baseDict, id: baseSymbol),
         let quoteDict = json[Key.quote.rawValue] as? [String: Any],
         let quoteSymbol = symbols[safe: 1],
         let quote = try? CurrencyData(json: quoteDict, id: quoteSymbol) else {
         throw ParseError.parseFailed
      }

      self.id = id
      baseCurrency = base
      quoteCurrency = quote
      exchanges = exchangesDict.compactMap { ExchangeData(name: $0) }
   }
}

extension HistoricalPriceData: JsonDeserializable {
   private enum Key: String {
      case time
      case close
      case high
      case low
      case open
      case volumefrom
      case volumeto
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let time = json[Key.time.rawValue] as? Int,
         let close = json[Key.close.rawValue] as? Double,
         let high = json[Key.high.rawValue] as? Double,
         let low = json[Key.low.rawValue] as? Double,
         let open = json[Key.open.rawValue] as? Double,
         let volumeFrom = json[Key.volumefrom.rawValue] as? Double,
         let volumeTo = json[Key.volumeto.rawValue] as? Double else {
         throw ParseError.parseFailed
      }

      self.time = time
      self.close = close
      self.high = high
      self.low = low
      self.open = open
      self.volumeFrom = volumeFrom
      self.volumeTo = volumeTo
   }
}

extension HistoricalPriceListData: JsonDeserializable {
   init(json: Any) throws {
      fatalError("init(json:) not implemented")
   }

   init(json: Any, fromCurrency: String, toCurrency: String, exchange: String) throws {
      guard let json = json as? [String: Any],
         let data = json["Data"] as? [[String: Any]] else {
         throw ParseError.parseFailed
      }

      let historicalPrices = try data.compactMap { historicalPrice in
         try HistoricalPriceData(json: historicalPrice)
      }

      self.historicalPrices = historicalPrices
      self.exchange = exchange
      baseCurrency = fromCurrency
      quoteCurrency = toCurrency
      modifyDate = Date()
   }
}

extension CurrencyPairData: JsonDeserializable {
   private enum Key: String {
      case baseCurrency
      case quoteCurrency
      case exchange
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let baseCurrencyData = json[Key.baseCurrency.rawValue] as? [String: Any],
         let baseCurrency = try? CurrencyData(json: baseCurrencyData),
         let quoteCurrencyData = json[Key.quoteCurrency.rawValue] as? [String: Any],
         let quoteCurrency = try? CurrencyData(json: quoteCurrencyData),
         let exchangeData = json[Key.exchange.rawValue] as? [String: Any],
         let exchange = try? ExchangeData(json: exchangeData) else {
         throw ParseError.parseFailed
      }
      self.baseCurrency = baseCurrency
      self.quoteCurrency = quoteCurrency
      self.exchange = exchange
      price = 0
   }
}

extension CurrencyDetailData: JsonDeserializable {
   private enum Key: String {
      // Top layer
      case raw
      case display

      // Content
      case fromSymbol
      case toSymbol
      case price
      case volume24Hour
      case open24Hour
      case high24Hour
      case low24Hour
      case change24Hour
      case changePct24Hour
      case mktcap

      var upper: String {
         return rawValue.uppercased()
      }
   }

   init(json: Any) throws {
      fatalError("init(json:) not implemented")
   }

   init(json: Any, currencyPair: CurrencyPair) throws {
      let fromCurrency = currencyPair.baseCurrency.symbol
      let toCurrency = currencyPair.quoteCurrency.symbol

      guard let json = json as? [String: Any],
         let rawContent = json[Key.raw.upper] as? [String: Any],
         let rawFromCurreny = rawContent[fromCurrency] as? [String: Any],
         let raw = rawFromCurreny[toCurrency] as? [String: Any],
         let displayContent = json[Key.display.upper] as? [String: Any],
         let displayFromCurreny = displayContent[fromCurrency] as? [String: Any],
         let display = displayFromCurreny[toCurrency] as? [String: Any],
         let fromSymbolRaw = raw[Key.fromSymbol.upper] as? String,
         let toSymbolRaw = raw[Key.toSymbol.upper] as? String,
         let price = raw[Key.price.upper] as? Double,
         let volume24Hour = raw[Key.volume24Hour.upper] as? Double,
         let open24Hour = raw[Key.open24Hour.upper] as? Double,
         let high24Hour = raw[Key.high24Hour.upper] as? Double,
         let low24Hour = raw[Key.low24Hour.upper] as? Double,
         let change24Hour = raw[Key.change24Hour.upper] as? Double,
         let changePct24Hour = raw[Key.changePct24Hour.upper] as? Double,
         let displayFromSymbol = display[Key.fromSymbol.upper] as? String,
         let displayToSymbol = display[Key.toSymbol.upper] as? String,
         let marketCap = raw[Key.mktcap.upper] as? Double else {
         throw ParseError.parseFailed
      }

      self.fromCurrency = fromSymbolRaw
      self.toCurrency = toSymbolRaw
      self.price = price
      self.volume24Hour = volume24Hour
      self.open24Hour = open24Hour
      self.high24Hour = high24Hour
      self.low24Hour = low24Hour
      self.change24Hour = change24Hour
      changePct24hour = changePct24Hour
      fromDisplaySymbol = displayFromSymbol
      toDisplaySymbol = displayToSymbol
      self.marketCap = marketCap
      exchange = currencyPair.exchange.name
      modifyDate = Date()
   }
}

extension CurrencyData: JsonDeserializable {
   private enum Key: String {
      case id
      case name
      case symbol

      // for new api
      case n
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let id = json[Key.id.rawValue] as? String,
         let name = json[Key.name.rawValue] as? String,
         let symbol = json[Key.symbol.rawValue] as? String else {
         throw ParseError.parseFailed
      }

      self.id = id
      self.name = name
      self.symbol = symbol
   }

   init(json: Any, id: String) throws {
      guard let json = json as? [String: Any],
         let name = json[Key.n.rawValue] as? String else {
         throw ParseError.parseFailed
      }

      self.id = id
      self.name = name
      symbol = id
   }
}

extension AuthenticationTokenData: JsonDeserializable {
   private enum Key: String {
      case token
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let token = json[Key.token.rawValue] as? String else {
         throw ParseError.parseFailed
      }
      self.token = token
   }
}

extension ExchangeData: JsonDeserializable {
   private enum Key: String {
      case id
      case name
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let id = json[Key.id.rawValue] as? String,
         let name = json[Key.name.rawValue] as? String else {
         throw ParseError.parseFailed
      }

      self.id = id
      self.name = name
   }

   init(name: String) {
      id = name
      self.name = name
   }
}

extension WatchlistFirebaseData: JsonDeserializable {
   private enum Key: String {
      case id
      case name
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any] else {
         throw ParseError.parseFailed
      }

      self = try WatchlistFirebaseData.deserialize(data: json)
   }
}

extension WatchlistFirebaseListData: JsonDeserializable {
   private enum Key: String {
      case watchlist
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any] else {
         throw ParseError.parseFailed
      }

      let watchlist = json[Key.watchlist.rawValue] as? [[String: Any]] ?? []
      watchlistFirebaseDatas = watchlist.compactMap { try? WatchlistFirebaseData(json: $0) }
   }
}

extension WatchlistData: JsonDeserializable {
   private enum Key: String {
      case userId
      case watchlist
      case baseCurrency
      case quoteCurrency
      case exchange
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let currencyPairsData = json[Key.watchlist.rawValue] as? [[String: Any]] else {
         throw ParseError.parseFailed
      }
      currencyPairs = try currencyPairsData.map { try CurrencyPairData(json: $0) }
      id = Watchlist.defaultKey
      modifyDate = Date()
   }
}

extension StandardResponseData: JsonDeserializable {
   private enum Key: String {
      case message
   }

   init(json: Any) throws {
      debugPrint(json)
      guard let json = json as? [String: Any],
         let message = json[Key.message.rawValue] as? String else {
         throw ParseError.parseFailed
      }
      self.message = message
   }
}

extension AnonymousMigrationResponseData: JsonDeserializable {
   private enum Key: String {
      case success
      case totalWatchlist
      case totalPriceAlert
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any] else {
         throw ParseError.parseFailed
      }

      success = json[Key.success.rawValue] as? Bool
      numOfWatchlist = json[Key.totalWatchlist.rawValue] as? Int
      numOfPriceAlert = json[Key.totalPriceAlert.rawValue] as? Int
   }
}

extension AlertData: JsonDeserializable {
   private enum Key: String {
      case id
      case fromCurrency
      case toCurrency
      case exchange
      case comparison
      case reference
      case isEnabled
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let id = json[Key.id.rawValue] as? String,
         let base = json[Key.fromCurrency.rawValue] as? String,
         let quote = json[Key.toCurrency.rawValue] as? String,
         let exchange = json[Key.exchange.rawValue] as? String,
         let comparisonRaw = json[Key.comparison.rawValue] as? String,
         let comparison = AlertComparison(rawValue: comparisonRaw),
         let reference = json[Key.reference.rawValue] as? Double,
         let isEnabled = json[Key.isEnabled.rawValue] as? Bool else {
         throw ParseError.parseFailed
      }

      self.id = id
      self.base = base
      self.quote = quote
      self.exchange = exchange
      self.comparison = comparison
      self.reference = Decimal(string: reference.formatUsingSignificantDigits()) ?? Decimal(reference)
      self.isEnabled = isEnabled
   }
}

extension AlertListData: JsonDeserializable {
   private enum Key: String {
      case alerts
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let alertsRaw = json[Key.alerts.rawValue] as? [[String: Any]] else {
         throw ParseError.parseFailed
      }

      let alerts = try alertsRaw.compactMap { json in
         try AlertData(json: json)
      }

      id = AlertList.defaultKey
      self.alerts = alerts
      modifyDate = Date()
   }
}

extension CreateAlertResponseData: JsonDeserializable {
   private enum Key: String {
      case message
      case alert
   }

   init(json: Any) throws {
      guard let json = json as? [String: Any],
         let message = json[Key.message.rawValue] as? String,
         let id = json[Key.alert.rawValue] as? String else {
         throw ParseError.parseFailed
      }

      self.id = id
      self.message = message
   }
}

extension UpdateAlertResponseData: JsonDeserializable {
   private enum Key: String {
      case alert
   }

   init(json: Any) throws {
      debugPrint(json)
      guard let json = json as? [String: Any],
         let id = json[Key.alert.rawValue] as? String else {
         throw ParseError.parseFailed
      }
      self.id = id
   }
}
