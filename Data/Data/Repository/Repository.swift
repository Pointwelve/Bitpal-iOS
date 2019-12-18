//
//  Repository.swift
//  Data
//
//  Created by Ryne Cheow on 9/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

/// Provides access to Use Case coordinators for each Repository.
public struct Repository: AppRepositoryType {
   internal let provider: RepositoryProvider

   public let prices: AppPricesUseCaseCoordinatorContainerType
   public let watchlist: WatchlistUseCaseCoordinatorContainerType
   public let device: DeviceUseCaseCoordinatorContainerType
   public let deviceFingerprint: DeviceFingerprintUseCaseCoordinatorContainerType
   public let preferences: PreferencesUseCaseCoordinatorContainerType
   public let user: UserUseCaseCoordinatorContainerType
   public let stream: StreamUseCaseCoordinatorContainerType
   public let pushNotification: PushNotificationUseCaseCoordinatorContainerType
   public let alert: AlertUseCaseCoordinatorContainerType
   public let currencyPair: CurrencyPairUseCaseCoordinatorContainerType

   init(provider: RepositoryProvider) {
      let useCaseProvider = UseCaseProvider(repositoryProvider: provider)
      self.provider = provider
      prices = Prices(useCaseProvider: useCaseProvider)
      watchlist = Watchlist(useCaseProvider: useCaseProvider)
      device = Device(useCaseProvider: useCaseProvider)
      deviceFingerprint = DeviceFingerprint(useCaseProvider: useCaseProvider)
      preferences = Preferences(useCaseProvider: useCaseProvider)
      user = User(useCaseProvider: useCaseProvider)
      stream = Stream(useCaseProvider: useCaseProvider)
      pushNotification = PushNotification(useCaseProvider: useCaseProvider)
      alert = Alert(useCaseProvider: useCaseProvider)
      currencyPair = CurrencyPair(useCaseProvider: useCaseProvider)
   }
}

extension Repository {
   public struct Device: DeviceUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      public func isOnline() -> IsOnlineUseCaseCoordinator {
         return .init(getAction: useCaseProvider.device.isOnline.read)
      }
   }
}

extension Repository {
   public struct DeviceFingerprint: DeviceFingerprintUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      public func read() -> DeviceFingerprintUseCaseCoordinator {
         return .init(readAction: useCaseProvider.deviceFingerprint.read.read)
      }

      public func peek() -> DeviceFingerprintUseCaseCoordinator {
         return .init(readAction: useCaseProvider.deviceFingerprint.peek.peek)
      }

      public func delete() -> DeviceFingerprintDeleteUseCaseCoordinator {
         let block: () -> Observable<String> = {
            self.useCaseProvider.deviceFingerprint.delete.delete("")
         }
         return .init(deleteAction: block)
      }
   }
}

extension Repository {
   public struct Preferences: PreferencesUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      private var _preferences: UseCaseProvider.Preferences {
         return useCaseProvider.preferences
      }

      public func preferences(existing: Domain.Preferences,
                              preferredLanguageAction: @escaping () -> Language,
                              preferredThemeAction: @escaping () -> Theme,
                              preferredChartTypeAction: @escaping () -> ChartType)
         -> PreferencesUseCaseCoordinator {
         return .init(preferences: existing,
                      needsReset: false,
                      needsLocalization: false,
                      preferredLanguageAction: preferredLanguageAction,
                      preferredThemeAction: preferredThemeAction,
                      preferredChartTypeAction: preferredChartTypeAction,
                      readAction: _preferences.read.read,
                      writeAction: _preferences.write.write)
      }
   }
}

extension Repository {
   public struct Prices: AppPricesUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      private var _price: UseCaseProvider.Price {
         return useCaseProvider.price
      }

      public func currencyPairList() -> CurrencyPairListUseCaseCoordinator {
         return .init(getAction: _price.priceList.get)
      }

      public func streamPrice(request: GetPriceListRequest) -> StreamPriceUseCaseCoordinator {
         return .init(request: request, streamAction: _price.streamLatestPrice.stream)
      }

      public func historicalPrice(request: HistoricalPriceListRequest)
         -> HistoricalPriceListUseCaseCoordinator {
         return .init(request: request, getAction: _price.getHistoricalPrice.get)
      }

      public func currencyDetail(request: GetCurrencyDetailRequest) -> CurrencyDetailUseCaseCoordinator {
         return .init(request: request, getAction: _price.getCurrencyDetail.get)
      }
   }
}

extension Repository {
   public struct User: UserUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      private var _user: UseCaseProvider.User {
         return useCaseProvider.user
      }

      public func userIdentifier() -> UserIdentifierUseCaseCoordinator {
         return .init(getAction: _user.read.read)
      }

      public func authenticate() -> AuthenticationUseCaseCoordinator {
         return .init(readAction: _user.auth.read)
      }

      public func anonymousMigration(with request: AnonymousMigrationRequest)
         -> AnonymousMigrationUseCaseCoordinator {
         return .init(request: request, updateAction: _user.anonymousMigration.update)
      }

      public func setSkipUserMigration(value: Bool) -> SetSkipUserMigrationUseCaseCoordinator {
         let block: (Bool) -> Observable<Bool> = { value in
            self._user.setSkipUserMigration.set(value, for: "")
         }
         return .init(request: value, setAction: block)
      }

      public func peekSkipUserMigration() -> PeekSkipUserMigrationUseCaseCoordinator {
         return .init(peekAction: _user.peekSkipUserMigration.peek)
      }
   }
}

extension Repository {
   public struct Watchlist: WatchlistUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      private var _watchlist: UseCaseProvider.Watchlist {
         return useCaseProvider.watchlist
      }

      public func peekWatchlist() -> PeekWatchlistUseCaseCoordinator {
         return .init(readAction: _watchlist.peek.peek)
      }

      public func writeWatchlist(request: SetWatchlistRequest) -> SetWatchlistUseCaseCoordinator {
         return .init(request: request, getAction: _watchlist.set.get)
      }

      public func watchlist() -> GetWatchlistUseCaseCoordinator {
         return .init(readAction: _watchlist.get.read)
      }
   }
}

extension Repository {
   public struct Stream: StreamUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      private var _stream: UseCaseProvider.Stream {
         return useCaseProvider.stream
      }

      public func unsubscribe() -> StreamUseCaseCoordinator {
         return .init(readAction: _stream.unsubscribe.read)
      }
   }
}

extension Repository {
   public struct PushNotification: PushNotificationUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      private var _pushNotification: UseCaseProvider.PushNotification {
         return useCaseProvider.pushNotification
      }

      public func register(token: String) -> PushNotificationUseCaseCoordinator {
         return .init(request: token, getAction: _pushNotification.register.get)
      }
   }
}

extension Repository {
   public struct Alert: AlertUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      private var _alert: UseCaseProvider.Alert {
         return useCaseProvider.alert
      }

      public func alerts() -> AlertUseCaseCoordinator {
         return .init(request: AlertList.defaultKey, getAction: _alert.alerts.get)
      }

      public func createAlert(request: CreateAlertRequest) -> CreateAlertUseCaseCoordinator {
         return .init(request: request, updateAction: _alert.createAlert.update)
      }

      public func deleteAlert(request: String) -> DeleteAlertUseCaseCoordinator {
         return .init(request: request, deleteAction: _alert.deleteAlert.delete)
      }

      public func updateAlert(request: Domain.Alert) -> UpdateAlertUseCaseCoordinator {
         return .init(request: request, updateAction: _alert.updateAlert.update)
      }
   }
}

extension Repository {
   public struct CurrencyPair: CurrencyPairUseCaseCoordinatorContainerType {
      internal let useCaseProvider: UseCaseProvider

      private var _currencyPair: UseCaseProvider.CurrencyPair {
         return useCaseProvider.currencyPair
      }

      public func getCurrecnyPair(request: String) -> GetCurrencyPairUseCaseCoordinator {
         return .init(request: request, getAction: _currencyPair.getCurrencyPair.get)
      }
   }
}
