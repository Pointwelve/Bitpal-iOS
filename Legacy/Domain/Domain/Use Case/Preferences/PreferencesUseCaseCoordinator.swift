//
//  PreferencesUseCaseCoordinator.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct PreferencesUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<Preferences>
   public typealias WriteAction = (Preferences) -> Observable<Preferences>
   public typealias PreferredLanguageAction = () -> Language
   public typealias PreferredThemeAction = () -> Theme
   public typealias PreferredChartTypeAction = () -> ChartType

   public let preferences: Preferences

   public let needsReset: Bool

   public let needsLocalization: Bool

   let preferredLanguageAction: PreferredLanguageAction

   let preferredThemeAction: PreferredThemeAction

   let preferredChartTypeAction: PreferredChartTypeAction

   let readAction: ReadAction

   let writeAction: WriteAction

   public init(preferences: Preferences,
               needsReset: Bool = false,
               needsLocalization: Bool = false,
               preferredLanguageAction: @escaping PreferredLanguageAction,
               preferredThemeAction: @escaping PreferredThemeAction,
               preferredChartTypeAction: @escaping PreferredChartTypeAction,
               readAction: @escaping ReadAction,
               writeAction: @escaping WriteAction) {
      self.preferences = preferences
      self.preferredLanguageAction = preferredLanguageAction
      self.preferredThemeAction = preferredThemeAction
      self.preferredChartTypeAction = preferredChartTypeAction
      self.needsReset = needsReset
      self.needsLocalization = needsLocalization
      self.readAction = readAction
      self.writeAction = writeAction
   }

   public var bestLanguage: Language {
      return preferences.language ?? preferredLanguageAction()
   }

   public var bestTheme: Theme {
      return preferences.theme ?? preferredThemeAction()
   }

   public var bestChartType: ChartType {
      return preferences.chartType ?? preferredChartTypeAction()
   }

   // MARK: - Requests

   func readRequest() -> Observable<Preferences> {
      return readAction()
   }

   func writeRequest() -> Observable<Preferences> {
      return writeAction(preferences)
   }

   // MARK: - Executors

   func read() -> Observable<PreferencesUseCaseCoordinator> {
      return readRequest().map(replacing)
   }

   func write() -> Observable<PreferencesUseCaseCoordinator> {
      return writeRequest().map(replacing)
   }

   // MARK: - Results

   public func readResult() -> Observable<Result<PreferencesUseCaseCoordinator>> {
      return result(from: read())
         .flatMap(handle)
         .startWith(.content(.with(self, .loading)))
   }

   public func writeResult() -> Observable<Result<PreferencesUseCaseCoordinator>> {
      if needsLocalization {
         return replacing(needsReset: false, needsLocalization: false).writeResult()
      } else {
         return result(from: write()).startWith(.content(.with(self, .loading)))
      }
   }

   func handle(result: Result<PreferencesUseCaseCoordinator>)
      -> Observable<Result<PreferencesUseCaseCoordinator>> {
      switch result.flattened {
      case let .failure(failure):
         switch failure {
         case let .error(error):
            switch error {
            case ParseError.parseFailed:
               // On failure, we can assume we haven't set any preferences before, we should
               // initialise it with installation = true
               return replacing(installed: true)
                  .writeResult()
            default:
               return .just(result)
            }
         default:
            return .just(result)
         }
      default:
         return .just(result)
      }
   }

   // MARK: - Replacements

   public func replacing(installed: Bool) -> PreferencesUseCaseCoordinator {
      return replacing(preferences: preferences.replacing(installed: installed))
   }

   public func replacing(language: Language) -> PreferencesUseCaseCoordinator {
      return replacing(preferences: preferences.replacing(language: language))
   }

   public func replacing(theme: Theme) -> PreferencesUseCaseCoordinator {
      return replacing(preferences: preferences.replacing(theme: theme))
   }

   public func replacing(chartType: ChartType) -> PreferencesUseCaseCoordinator {
      return replacing(preferences: preferences.replacing(chartType: chartType))
   }

   public func replacing(needsReset newNeedsReset: Bool,
                         needsLocalization newNeedsLocalization: Bool) -> PreferencesUseCaseCoordinator {
      return .init(preferences: preferences,
                   needsReset: newNeedsReset,
                   needsLocalization: newNeedsLocalization,
                   preferredLanguageAction: preferredLanguageAction,
                   preferredThemeAction: preferredThemeAction,
                   preferredChartTypeAction: preferredChartTypeAction,
                   readAction: readAction,
                   writeAction: writeAction)
   }

   internal func replacing(preferences newPreferences: Preferences) -> PreferencesUseCaseCoordinator {
      // Only override invalidated flag if it is currently false
      // swiftlint:disable identifier_name
      let _reset = needsReset == true ? true : preferences.databaseName != nil
         && preferences.databaseName != newPreferences.databaseName

      return .init(preferences: newPreferences,
                   needsReset: _reset,
                   needsLocalization: _reset,
                   preferredLanguageAction: preferredLanguageAction,
                   preferredThemeAction: preferredThemeAction,
                   preferredChartTypeAction: preferredChartTypeAction,
                   readAction: readAction,
                   writeAction: writeAction)
   }
}
