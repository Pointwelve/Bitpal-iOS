//
//  SessionManager.swift
//  Data
//
//  Created by Ryne Cheow on 9/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxOptional
import RxSwift

protocol SessionManagerType {
   var configurationRelay: BehaviorRelay<ConfigurationUseCaseCoordinator?> { get }

   var configuration: Observable<ConfigurationUseCaseCoordinator> { get }

   var preferencesRepository: PreferencesRepository { get }

   var onMemoryWarning: Observable<Void> { get }

   var apiClient: RestAPIClient! { get set }

   func getLanguage() -> Observable<Language?>

   func getApiRequest(for router: Router) -> Observable<(String, Language, String, (() -> Observable<String>)?)>
}

public final class SessionManager: SessionManagerType {
   internal let configurationRelay = BehaviorRelay<ConfigurationUseCaseCoordinator?>(value: nil)
   public var configuration: Observable<ConfigurationUseCaseCoordinator> {
      return configurationRelay.asObservable().filterNil()
   }

   internal var preferencesRepository: PreferencesRepository
   internal var apiClient: RestAPIClient!

   internal let onMemoryWarning: Observable<Void>
   private let onAppEnteredBackground: Observable<Void>
   private let onAppEnteredForeground: Observable<Void>
   private let onAppWillTerminate: Observable<Void>

   private let disposeBag = DisposeBag()

   private var functionsClient: RestAPIClient!
   private var socketClient: SocketClient!

   public let getPreferredLanguage: () -> Language
   public let getPreferredTheme: () -> Theme
   public let getPreferredChartType: () -> ChartType
   public private(set) var repository: AppRepositoryType!

   private let firebaseAuthenticationProvider: FirebaseAuthProviderType

   public init(bundle: Bundle,
               getPreferredLanguage: @escaping () -> Language,
               getPreferredTheme: @escaping () -> Theme,
               getPreferredChartType: @escaping () -> ChartType,
               getFirebaseAuth: FirebaseAuthProviderType,
               memoryWarning: Observable<Void>,
               appEnteredBackground: Observable<Void>,
               appEnteredForeground: Observable<Void>,
               appWillTerminate: Observable<Void>) {
      UseCaseCoordinatorFactory.Configuration
         .read(from: bundle)
         .readResult()
         .filter { $0.hasContent }
         .map { $0.contentValue! } // Value must be present
         .bind(to: configurationRelay)
         .disposed(by: disposeBag)

      preferencesRepository = PreferencesRepository()
      self.getPreferredLanguage = getPreferredLanguage
      self.getPreferredTheme = getPreferredTheme
      self.getPreferredChartType = getPreferredChartType
      onMemoryWarning = memoryWarning
      onAppEnteredBackground = appEnteredBackground
      onAppEnteredForeground = appEnteredForeground
      onAppWillTerminate = appWillTerminate

      firebaseAuthenticationProvider = getFirebaseAuth
      apiClient = RestAPIClient(getConfigurationAction: getApiRequest,
                                readPreferencesAction: getLanguage)
      functionsClient = RestAPIClient(getConfigurationAction: getFunctionsRequest, readPreferencesAction: getLanguage)
      socketClient = SocketClient(getSocketAction: getSocketRequest,
                                  onAppEnteredBackground: appEnteredBackground,
                                  onAppEnteredForeground: appEnteredForeground)

      refresh(with: nil)
   }

   internal func getLanguage() -> Observable<Language?> {
      return preferencesRepository
         .read()
         .map { $0.language }
   }

   func getApiRequest(for router: Router)
      -> Observable<(String, Language, String, (() -> Observable<String>)?)> {
      return configuration.map { ($0.apiHost,
                                  self.getPreferredLanguage(),
                                  $0.apiKey,
                                  nil) }
   }

   private func getFunctionsRequest(for router: Router)
      -> Observable<(String, Language, String, (() -> Observable<String>)?)> {
      return configuration.map { ($0.functionsHost,
                                  self.getPreferredLanguage(),
                                  $0.apiKey,
                                  self.firebaseAuthenticationProvider.authenticationToken) }
   }

   private func getSocketRequest() -> Observable<String> {
      return configuration.map { "wss://\($0.socketHost)/v2?api_key=\($0.apiKey)" }
   }

   public var isUsingTemporaryPreferences: Bool {
      return preferencesRepository is TemporaryPreferencesRepository
   }

   public func useTemporaryPreferences(with theme: Theme, language: Language) {
      preferencesRepository = TemporaryPreferencesRepository(theme: theme, language: language)
   }

   public func usePersistedPreferences() {
      preferencesRepository = PreferencesRepository()
   }

   public func refresh(with databaseName: String?) {
      // Only recreate repository if the database name has changed
      // swiftlint:disable force_cast
      let currentDatabaseName = repository != nil ?
         (repository as! Repository).provider.realmManager.fileName : nil
      let databaseNameChanged = databaseName.isEmpty ?
         currentDatabaseName.isEmpty != databaseName.isEmpty : currentDatabaseName != databaseName

      if repository == nil || databaseNameChanged {
         let provider = RepositoryProvider(apiClient: apiClient,
                                           functionsClient: functionsClient,
                                           socketClient: socketClient,
                                           firebaseAuthProvider: firebaseAuthenticationProvider,
                                           preferencesRepository: preferencesRepository,
                                           realmManager: RealmManager(with: databaseName),
                                           onMemoryWarning: onMemoryWarning,
                                           onAppEnteredBackground: onAppEnteredBackground,
                                           onAppEnteredForeground: onAppEnteredForeground,
                                           onAppWillTerminate: onAppWillTerminate)
         repository = Repository(provider: provider)
      }
   }
}

extension SessionManager {
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
