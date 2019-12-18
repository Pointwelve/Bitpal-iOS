//
//  WidgetPreferenceUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 4/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct WidgetPreferenceUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<Preferences>
   public typealias WriteAction = (Preferences) -> Observable<Preferences>

   public let preferences: Preferences

   let readAction: ReadAction

   let writeAction: WriteAction

   public init(preferences: Preferences,
               readAction: @escaping ReadAction,
               writeAction: @escaping WriteAction) {
      self.preferences = preferences
      self.readAction = readAction
      self.writeAction = writeAction
   }

   // MARK: - Requests

   func readRequest() -> Observable<Preferences> {
      return readAction()
   }

   func writeRequest() -> Observable<Preferences> {
      return writeAction(preferences)
   }

   // MARK: - Executors

   func read() -> Observable<WidgetPreferenceUseCaseCoordinator> {
      return readRequest().map(replacing)
   }

   func write() -> Observable<WidgetPreferenceUseCaseCoordinator> {
      return writeRequest().map(replacing)
   }

   // MARK: - Results

   public func readResult() -> Observable<Result<WidgetPreferenceUseCaseCoordinator>> {
      return result(from: read())
         .flatMap(handle)
         .startWith(.content(.with(self, .loading)))
   }

   public func writeResult() -> Observable<Result<WidgetPreferenceUseCaseCoordinator>> {
      return result(from: write()).startWith(.content(.with(self, .loading)))
   }

   func handle(result: Result<WidgetPreferenceUseCaseCoordinator>)
      -> Observable<Result<WidgetPreferenceUseCaseCoordinator>> {
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

   public func replacing(installed: Bool) -> WidgetPreferenceUseCaseCoordinator {
      return replacing(preferences: preferences.replacing(installed: installed))
   }

   internal func replacing(preferences newPreferences: Preferences) -> WidgetPreferenceUseCaseCoordinator {
      return .init(preferences: newPreferences,
                   readAction: readAction,
                   writeAction: writeAction)
   }
}
