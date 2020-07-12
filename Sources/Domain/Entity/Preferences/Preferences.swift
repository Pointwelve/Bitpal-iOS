//
//  Preferences.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

public struct Preferences: Equatable, DomainType {
   public var language: Language?
   public var theme: Theme?
   public var databaseName: String?
   public var installed: Bool
   public var chartType: ChartType?

   public init(language: Language? = nil,
               theme: Theme? = nil,
               databaseName: String? = nil,
               installed: Bool = false,
               chartType: ChartType? = nil) {
      self.language = language
      self.theme = theme
      self.databaseName = databaseName
      self.installed = installed
      self.chartType = chartType
   }
}

private enum DatabaseNameComponent: String {
   case startingCharacter = "("
   case splittingCharacter = "_"
   case endingCharacter = ")"
}

extension Preferences {
   internal func willInvalidateDatabase(with language: Language) -> Bool {
      guard
         let uniqueKey = databaseName,
         !uniqueKey.isEmpty,
         let countryLanguageInfo = uniqueKey
         .components(separatedBy: DatabaseNameComponent.startingCharacter.rawValue)
         .last?.components(separatedBy: DatabaseNameComponent.endingCharacter.rawValue).first,
         let currentLanguageCode = countryLanguageInfo
         .components(separatedBy: DatabaseNameComponent.splittingCharacter.rawValue)
         .last else {
         return true
      }

      // Database is invalid if either the country or language has changed.
      // This invalidates the content that belongs to a particular catalogue (country)
      // or content that is presented in an incorrect language.
      return currentLanguageCode != language.rawValue
   }

   internal func newDatabaseName(with language: Language) -> String? {
      guard willInvalidateDatabase(with: language) else {
         return databaseName
      }
      // Set a database name using the country app site + language code
      // plus a unique key (to stop users swapping back to an already invalidated
      // database).
      let uuid = UUID().uuidString
      let uniqueKey = "\(DatabaseNameComponent.startingCharacter.rawValue)" +
         "\(DatabaseNameComponent.splittingCharacter.rawValue)\(language.rawValue)" +
         "\(DatabaseNameComponent.endingCharacter.rawValue)\(uuid)"
      return uniqueKey
   }

   internal func replacing(language newLanguage: Language? = nil,
                           theme newTheme: Theme? = nil,
                           installed newInstalled: Bool? = nil,
                           chartType: ChartType? = nil) -> Preferences {
      // swiftlint:disable identifier_name
      let _language = newLanguage ?? language ?? .default
      let _newDatabaseName = newDatabaseName(with: _language)

      return .init(language: newLanguage ?? language,
                   theme: newTheme ?? theme,
                   databaseName: _newDatabaseName ?? databaseName,
                   installed: newInstalled ?? installed,
                   chartType: chartType ?? .line)
   }
}
