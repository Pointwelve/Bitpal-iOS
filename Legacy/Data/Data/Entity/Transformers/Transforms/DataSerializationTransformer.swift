//
//  DataSerializationTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

// MARK: - Mapping

extension PreferencesData: Serializable {
   enum Key: String {
      case language
      case theme
      case databaseName
      case installed
      case chartType
   }

   typealias Input = [String: Any]
   typealias Output = PreferencesData

   func serialized() -> Input {
      var values = Input()
      if let language = language?.code {
         values[Key.language.rawValue] = language
      }

      if let theme = theme?.name {
         values[Key.theme.rawValue] = theme
      }

      if let databaseName = databaseName {
         values[Key.databaseName.rawValue] = databaseName
      }

      values[Key.installed.rawValue] = installed
      values[Key.chartType.rawValue] = chartType

      return values
   }

   static func deserialize(data: Input) throws -> Output {
      guard let installed = data[Key.installed.rawValue] as? Bool else {
         throw ParseError.parseFailed
      }

      var language: LanguageData?

      if let languageCode = data[Key.language.rawValue] as? String {
         language = try LanguageData(code: languageCode)
      }

      var theme: ThemeData?

      if let themeName = data[Key.theme.rawValue] as? String {
         theme = try ThemeData(name: themeName)
      }

      let databaseName = data[Key.databaseName.rawValue] as? String
      let chartType = data[Key.chartType.rawValue] as? Int

      return PreferencesData(language: language,
                             theme: theme,
                             databaseName: databaseName,
                             installed: installed,
                             chartType: chartType)
   }
}

extension WatchlistFirebaseData: Serializable {
   private enum Key: String {
      case pair
      case exchange
   }

   typealias Input = [String: Any]
   typealias Output = WatchlistFirebaseData

   func serialized() -> Input {
      var values = Input()
      values[Key.pair.rawValue] = pair
      values[Key.exchange.rawValue] = exchange

      return values
   }

   static func deserialize(data: Input) throws -> Output {
      guard let pair = data[Key.pair.rawValue] as? String,
         let exchange = data[Key.exchange.rawValue] as? String else {
         throw ParseError.parseFailed
      }

      return Output(exchange: exchange, pair: pair)
   }
}

extension DeviceFingerprintData: Serializable {
   enum Key: String {
      case data
   }

   typealias Input = [String: String]
   typealias Output = DeviceFingerprintData

   func serialized() -> Input {
      return [Key.data.rawValue: data]
   }

   static func deserialize(data: Input) throws -> Output {
      guard let data = data[Key.data.rawValue] else {
         throw ParseError.parseFailed
      }

      return Output(data: data)
   }
}
