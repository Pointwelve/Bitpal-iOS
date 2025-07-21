//
//  WidgetSessionManager.swift
//  Data
//
//  Created by James Lai on 5/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxOptional
import RxSwift

public final class WidgetSessionManager: SessionManagerType {
   internal let configurationRelay = BehaviorRelay<ConfigurationUseCaseCoordinator?>(value: nil)
   public var configuration: Observable<ConfigurationUseCaseCoordinator> {
      return configurationRelay.asObservable().filterNil()
   }

   internal var preferencesRepository: PreferencesRepository
   internal var apiClient: RestAPIClient!
   internal let onMemoryWarning: Observable<Void>

   private let disposeBag = DisposeBag()

   public private(set) var repository: WidgetRepositoryType!

   public init(bundle: Bundle,
               memoryWarning: Observable<Void>) {
      UseCaseCoordinatorFactory.Configuration
         .read(from: bundle)
         .readResult()
         .filter { $0.hasContent }
         .map { $0.contentValue! } // Value must be present
         .bind(to: configurationRelay)
         .disposed(by: disposeBag)

      onMemoryWarning = memoryWarning
      preferencesRepository = PreferencesRepository(target: .widget)
      apiClient = RestAPIClient(getConfigurationAction: getApiRequest,
                                readPreferencesAction: getLanguage)

      refresh(with: nil)
   }

   internal func getLanguage() -> Observable<Language?> {
      return preferencesRepository
         .read()
         .map { $0.language }
   }

   internal func getApiRequest(for router: Router) -> Observable<(String, Language, String, (() -> Observable<String>)?)> {
      return configuration.map { ($0.apiHost, Language.default, $0.apiKey, nil) }
   }

   public func refresh(with databaseName: String?) {
      // Only recreate repository if the database name has changed
      // swiftlint:disable force_cast
      let currentDatabaseName = repository != nil ?
         (repository as! WidgetRepository).provider.realmManager.fileName : nil
      let databaseNameChanged = databaseName.isEmpty ?
         currentDatabaseName.isEmpty != databaseName.isEmpty : currentDatabaseName != databaseName

      if repository == nil || databaseNameChanged {
         let provider = WidgetRepositoryProvider(apiClient: apiClient,
                                                 preferencesRepository: preferencesRepository,
                                                 realmManager: RealmManager(with: databaseName, target: .widget),
                                                 onMemoryWarning: onMemoryWarning)
         repository = WidgetRepository(provider: provider)
      }
   }
}

extension WidgetSessionManager {
   enum UseCaseCoordinatorFactory {
      enum Configuration {
         /// Use case coordinator for reading configuration.
         static func read(from bundle: Bundle) -> ConfigurationUseCaseCoordinator {
            // swiftlint:disable force_try
            let repository = ConfigurationRepository(storage: try! ConfigurationPlistStorage(inBundle: bundle))
            let useCase = ReadConfigurationUseCaseType(repository: repository,
                                                       schedulerExecutor: ImmediateSchedulerExecutor())
            return ConfigurationUseCaseCoordinator(readAction: useCase.read)
         }
      }
   }
}
