//
//  AppPreference.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

/// User's application preferences.
protocol AppPreferencesType {
   /// Current language that the app is localized in.
   var language: Driver<Language> { get }

   /// Is Language selected by user.
   var isLanguageSelected: Driver<Bool> { get }

   /// Current theme that the app is colored in.
   var theme: Driver<Theme> { get }

   /// Current chart type that the app is using
   var chartType: Driver<ChartType> { get }

   /// Provider of services which contain use cases to execute.
   var serviceProvider: AppServiceProviderType { get }

   /// Triggered when the database has been recreated.
   var isInvalidated: Driver<Void> { get }

   /// `true` if the app has finished initializing Keychain.
   var isInstalled: Driver<Bool> { get }

   /// Change theme the user is using the app in.
   ///
   /// - Parameter theme: Theme the user is using the app in.
   func set(theme: Theme)

   /// Change language the app is localized in.
   ///
   /// - Parameter language: Language to localize the app into.
   func set(language: Language)

   /// Change chart type the user is using the app in.
   ///
   /// - Parameter chartType: ChartType the user is using the app in.
   func set(chartType: ChartType)

   /// Store preferences so changes will be remembered in subsequent launches.
   func save()

   /// Apply localization changes to recreate the service provider.
   /// This will automatically happen when `save` is called, however, for onboarding
   /// this method needs to be used prior to applying changes.
   func localize()
}

class AppPreferences: AppPreferencesType {
   let disposeBag = DisposeBag()

   private let loaded = BehaviorRelay<Bool>(value: false)
   private let coordinator: BehaviorRelay<PreferencesUseCaseCoordinator>

   let language: Driver<Language>
   let theme: Driver<Theme>
   let chartType: Driver<ChartType>
   let isLanguageSelected: Driver<Bool>

   let isInstalled: Driver<Bool>
   let isLoaded: Driver<Bool>
   let isInvalidated: Driver<Void>
   let serviceProvider: AppServiceProviderType

   init(serviceProvider: ServiceProvider = .shared) {
      // Interestingly changes to the Preferences actually recreates the ServiceProvider
      // which owns the associated UseCases that the Preferences relies on (due to the need to
      // recreate an ApiClient and RealmDB).
      // Therefore we need to store the previous state prior to the recreation of the ServiceProvider
      // and we need a default state prior to initializing the ServiceProvider.

      // Create temporary values
      let initialPreferences = Preferences()

      self.serviceProvider = serviceProvider
      self.serviceProvider.sessionManager.refresh(with: initialPreferences.databaseName)

      // There is a bi-directional relationship here, therefore we should create these in this order.
      coordinator = BehaviorRelay(value: serviceProvider.repository.preferences
         .preferences(existing: initialPreferences,
                      preferredLanguageAction: serviceProvider.sessionManager.getPreferredLanguage,
                      preferredThemeAction: serviceProvider.sessionManager.getPreferredTheme,
                      preferredChartTypeAction: serviceProvider.sessionManager.getPreferredChartType))

      // Observe changes
      let driver = coordinator.asDriver()

      theme = driver.map { $0.bestTheme }.distinctUntilChanged()
         .do(onNext: { ThemeProvider.setCurrentTheme(theme: $0) })
      language = driver.map { $0.bestLanguage }.distinctUntilChanged()
      chartType = driver.map { $0.bestChartType }.distinctUntilChanged()

      isLanguageSelected = driver.map { $0.preferences.language != nil }.distinctUntilChanged()

      // The following should only be set after we have loaded
      isLoaded = loaded.asDriver().ifTrue()
      isInstalled = Driver.combineLatest(isLoaded, driver.map { $0.preferences.installed }) { $1 }
      isInvalidated = Driver.combineLatest(isLoaded, driver.map { $0.needsReset }) { $1 }.ifTrue().void()

      observeCoordinatorChanges()
      read()
   }

   func set(theme: Theme) {
      if theme != coordinator.value.preferences.theme {
         coordinator.accept(coordinator.value.replacing(theme: theme))
      }
   }

   func set(language: Language) {
      if language != coordinator.value.preferences.language {
         coordinator.accept(coordinator.value.replacing(language: language))
      }
   }

   func set(chartType: ChartType) {
      if chartType != coordinator.value.preferences.chartType {
         coordinator.accept(coordinator.value.replacing(chartType: chartType))
      }
   }

   private func observeCoordinatorChanges() {
      coordinator.asDriver()
         .drive(onNext: { [weak self] newCoordinator in
            guard let `self` = self else {
               return
            }
            // If the coordinator indicates that localization is needed or the gender is nil (we are onboarding)
            // or we haven't initialized a service provider yet, lets create one using the coordinator.
            if newCoordinator.needsLocalization || self.loaded.value == false {
               self.serviceProvider.sessionManager.refresh(with: newCoordinator.preferences.databaseName)
               if !newCoordinator.preferences.databaseName.isEmpty, self.loaded.value == false {
                  self.loaded.accept(true)
               }
            }
         })
         .disposed(by: disposeBag)
   }

   func localize() {
      serviceProvider.sessionManager
         .useTemporaryPreferences(with: coordinator.value.bestTheme,
                                  language: coordinator.value.bestLanguage)
   }

   private func read() {
      // Read stored value
      coordinator.value.readResult()
         .subscribe(onNext: { result in
            switch result {
            case .failure(.offline):
               break
            case let .failure(.error(error)):
               debugPrint("Failed to load preferences: \(error)")
            case let .content(.with(coordinator, _)):
               self.coordinator.accept(coordinator)
            default:
               break
            }
         })
         .disposed(by: disposeBag)
   }

   func save() {
      if serviceProvider.sessionManager.isUsingTemporaryPreferences {
         serviceProvider.sessionManager.usePersistedPreferences()
      }

      coordinator.value.writeResult()
         .do(onNext: { result in
            switch result {
            case let .failure(.error(error)):
               fatalError("Unhandled error: \(error)")
            default:
               break
            }
         })
         .filter { $0.hasContent }
         .map { $0.contentValue }
         .filterNil()
         .bind(to: coordinator)
         .disposed(by: disposeBag)
   }
}
