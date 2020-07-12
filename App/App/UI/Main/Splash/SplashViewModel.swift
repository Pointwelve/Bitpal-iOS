//
//  SplashViewModel.swift
//  App
//
//  Created by Li Hao Lai on 26/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import CloudKit
import Domain
import Foundation
import RxCocoa
import RxSwift

final class SplashViewModel: TransformableViewModelType, Navigable {
   struct Input {
      var migrationSkipAction: Driver<Void>
      var migrationProceedAction: Driver<Void>
   }

   struct Output {
      let peekDeviceFingerprint: Driver<String?>
      let promptOverrideMigration: Driver<Bool>
      let authenticationSuccessful: Driver<Void>
      let tokenDriver: Driver<Void>
   }

   weak var navigator: SplashNavigatorType!

   init(navigator: SplashNavigatorType) {
      self.navigator = navigator
   }

   func transform(input: Input) -> Output {
      let repository = navigator.state.preferences.serviceProvider.repository
      let firebaseProvider = navigator.state.preferences.serviceProvider.firebaseAuthProvider
      let overrideMigration = BehaviorRelay<Bool?>(value: nil)
      let migrationUID = BehaviorRelay<String?>(value: nil)

      // get current deviceFingerprint
      let deviceFingerprint = repository.deviceFingerprint.peek()
         .readResult()
         .filter { $0.hasContentOrFailed }
         .map { $0.contentValue?.data }
         .asDriver(onErrorJustReturn: nil)

      func anonymousMigration(identifier: String, override: Bool = false) -> Driver<AnonymousMigrationResponse?> {
         let request = AnonymousMigrationRequest(anonymousIdentifier: identifier,
                                                 override: override)

         return repository.user.anonymousMigration(with: request)
            .updateResult()
            .filter { $0.hasContent }
            .asDriver(onErrorJustReturn:
               .failure(.error(UseCaseError.executionFailed)))
            .map { $0.contentValue?.response }
            .flatMapLatest { response in
               guard let success = response?.success,
                  success else {
                  return .just(response)
               }

               return repository.deviceFingerprint.delete()
                  .deleteResult()
                  .filter { $0.hasContent }
                  .asDriver(onErrorJustReturn:
                     .failure(.error(UseCaseError.executionFailed)))
                  .map { _ in response }
            }
      }

      // authentication
      let authenticationDriver = repository.user.authenticate()
         .readResult()
         .asDriver(onErrorJustReturn:
            .failure(.error(UseCaseError.executionFailed)))
         .filter { $0.hasContent }
         .map { $0.contentValue?.user }
         .filterNil()

      let tokenDriver = authenticationDriver.flatMap { _ in
         firebaseProvider.authenticationToken().asDriver(onErrorJustReturn: "")
      }.do(onNext: { token in print(token) }).void()

      // Detect for migration
      let migrationRequired = Driver.combineLatest(authenticationDriver, deviceFingerprint)
         .map { [weak self] (arg) -> Bool in
            let (user, anonId) = arg
            // If anonymous ID exist
            guard let anonymousId = anonId else {
               self?.track(identifier: user.userId)
               return false
            }

            // If anonymous ID is not the current logged in user
            guard anonymousId != user.userId else {
               self?.track(anonymous: user.userId)
               return false
            }
            self?.track(identifier: user.userId)
            return true
         }.asDriver(onErrorJustReturn: false)

      let promptOverrideMigration = migrationRequired
         .withLatestFrom(deviceFingerprint.filterNil()) { ($0, $1) }
         .flatMapLatest { (arg) -> Driver<Bool> in
            let (required, identifier) = arg
            if required {
               return anonymousMigration(identifier: identifier)
                  .filterNil()
                  .map { $0.success == nil }
            }
            return .just(false)
         }

      // 2 branches of action if migration errors out
      // 1. Skips migration
      let skipMigration = input.migrationSkipAction.flatMapLatest { _ in
         repository.user.setSkipUserMigration(value: true)
            .setResult()
            .filter { $0.hasContent }
            .asDriver(onErrorJustReturn:
               .failure(.error(UseCaseError.executionFailed)))
            .void()
            // delay to finish animation
            .delay(.milliseconds(340))
      }

      // 2. Proceed with migration
      let migrate = input.migrationProceedAction.withLatestFrom(deviceFingerprint.filterNil())
         .flatMapLatest { identifier in
            anonymousMigration(identifier: identifier, override: true)
         }.void()

      let migrationNotRequired = migrationRequired.filter { !$0 }.void()

      let migrationSuccessful = Driver.zip(migrationRequired.filter { $0 },
                                           promptOverrideMigration.filter { !$0 })
         .map { $0 && $1 }.void()

      let authenticationSequence = [
         migrationNotRequired.asObservable(),
         migrationSuccessful.asObservable(),
         skipMigration.asObservable(),
         migrate.asObservable()
      ]

      func syncWatchlist() -> Observable<Void> {
         let currenciesCoordinator = navigator.state.preferences.serviceProvider
            .repository.prices.currencyPairList()
         let retrieveWatchlistCoordinator = navigator.state.preferences.serviceProvider
            .repository.watchlist.watchlist()
         let alertsCoordinator = navigator.state.preferences.serviceProvider
            .repository.alert.alerts()

         let currencies = currenciesCoordinator
            .getResult()
            .filter { $0.hasContent }

         let watchlistRetrieval = retrieveWatchlistCoordinator
            .readResult()
            .filter { $0.hasContent }

         let alerts = alertsCoordinator
            .getResult()
            .filter { $0.hasContent }

         return Observable.zip(currencies, watchlistRetrieval, alerts).void()
      }

      let authenticationSuccessful =
         Observable.amb(authenticationSequence).void().asDriver()
            .flatMapLatest { _ in syncWatchlist().asDriver() }
            .do(onNext: { [weak self] _ in
               self?.navigator.state.preferences.serviceProvider.appState.accept(.authenticated)
            })

      return .init(peekDeviceFingerprint: deviceFingerprint,
                   promptOverrideMigration: promptOverrideMigration,
                   authenticationSuccessful: authenticationSuccessful,
                   tokenDriver: tokenDriver)
   }

   private func track(identifier: String) {
      AnalyticsProvider.log(login: "iCloud", metadata: [
         "identifier": identifier,
         "locale": Locale.current.identifier,
         "version": Bundle.main.versionString
      ])
   }

   private func track(anonymous uid: String) {
      AnalyticsProvider.log(login: "Anonymous", metadata: [
         "identifier": uid,
         "locale": Locale.current.identifier,
         "version": Bundle.main.versionString
      ])
   }
}
