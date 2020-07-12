//
//  UseCaseProvider.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct UseCaseProvider {
   let device: Device
   let deviceFingerprint: DeviceFingerprint
   let preferences: Preferences
   let price: Price
   let user: User
   let watchlist: Watchlist
   let stream: Stream
   let pushNotification: PushNotification
   let alert: Alert
   let currencyPair: CurrencyPair

   init(repositoryProvider: RepositoryProvider) {
      device = .init(repositoryProvider: repositoryProvider)
      deviceFingerprint = .init(repositoryProvider: repositoryProvider)
      preferences = .init(repositoryProvider: repositoryProvider)
      price = .init(repositoryProvider: repositoryProvider)
      user = .init(repositoryProvider: repositoryProvider)
      watchlist = .init(repositoryProvider: repositoryProvider)
      stream = .init(repositoryProvider: repositoryProvider)
      pushNotification = .init(repositoryProvider: repositoryProvider)
      alert = .init(repositoryProvider: repositoryProvider)
      currencyPair = .init(repositoryProvider: repositoryProvider)
   }
}

extension UseCaseProvider {
   struct Device {
      /// Use case for determining if we are online.
      let isOnline: IsOnlineUseCaseType<IsOnlineRepository>

      init(repositoryProvider: RepositoryProvider) {
         isOnline = .init(repository: repositoryProvider.isOnline,
                          schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct DeviceFingerprint {
      let read: ReadDeviceFingerprintUseCaseType<DeviceFingerprintRepository>
      let peek: PeekDeviceFingerprintUseCaseType<DeviceFingerprintRepository>
      let delete: DeleteDeviceFingerprintUseCaseType<DeviceFingerprintRepository>

      init(repositoryProvider: RepositoryProvider) {
         read = .init(repository: repositoryProvider.deviceFingerprint,
                      schedulerExecutor: ImmediateSchedulerExecutor())
         peek = .init(repository: repositoryProvider.deviceFingerprint,
                      schedulerExecutor: ImmediateSchedulerExecutor())
         delete = .init(repository: repositoryProvider.deviceFingerprint,
                        schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct Preferences {
      /// Use case for reading user preferences.
      let read: ReadPreferencesUseCaseType<PreferencesRepository>
      /// Use case for writing user preferences.
      let write: WritePreferencesUseCaseType<PreferencesRepository>

      init(repositoryProvider: RepositoryProvider) {
         read = .init(repository: repositoryProvider.preferences,
                      schedulerExecutor: ImmediateSchedulerExecutor())
         write = .init(repository: repositoryProvider.preferences,
                       schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct Price {
      /// Use case for determining if we are online.
      let priceList: CurrencyPairListUseCaseType<CurrencyPairListRepository>
      let streamLatestPrice: StreamLatestPriceUseCaseType<StreamPriceRepository>
      let getHistoricalPrice: GetHistoricalPriceListUseCaseType<HistoricalPriceListRepository>
      let getCurrencyDetail: GetCurrencyDetailUseCaseType<CurrencyDetailRepository>

      init(repositoryProvider: RepositoryProvider) {
         priceList = .init(repository: repositoryProvider.currencyPairList,
                           schedulerExecutor: ImmediateSchedulerExecutor())
         streamLatestPrice = .init(repository: repositoryProvider.streamPrice,
                                   schedulerExecutor: ImmediateSchedulerExecutor())

         getHistoricalPrice = .init(repository: repositoryProvider.historicalPriceList,
                                    schedulerExecutor: ImmediateSchedulerExecutor())

         getCurrencyDetail = .init(repository: repositoryProvider.currencyDetail,
                                   schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct User {
      /// Use case for determining if we are online.
      let read: iCloudIdentifierUseCaseType<IdentifierRepository>
      let auth: AuthenticationUseCaseType<AuthenticationRepository>
      let anonymousMigration: AnonymousMigrationUseCaseType<AnonymousMigrationRepository>
      let setSkipUserMigration: SetSkipUserMigrationUseCaseType<SkipUserMigrationRepository>
      let peekSkipUserMigration: PeekSkipUserMigrationUseCaseType<SkipUserMigrationRepository>

      init(repositoryProvider: RepositoryProvider) {
         read = .init(repository: repositoryProvider.iCloudIdentifier,
                      schedulerExecutor: ImmediateSchedulerExecutor())

         auth = .init(repository: repositoryProvider.authentication,
                      schedulerExecutor: ImmediateSchedulerExecutor())

         anonymousMigration = .init(repository: repositoryProvider.anonymousMigration,
                                    schedulerExecutor: ImmediateSchedulerExecutor())

         setSkipUserMigration = .init(repository: repositoryProvider.skipUserMigration,
                                      schedulerExecutor: ImmediateSchedulerExecutor())

         peekSkipUserMigration = .init(repository: repositoryProvider.skipUserMigration,
                                       schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct Watchlist {
      /// Use case for determining if we are online.
      let set: SetWatchlistUseCaseType<WatchlistRepository>
      let get: GetWatchlistUseCaseType<WatchlistRepository>
      let peek: PeekWatchlistUseCaseType<WatchlistRepository>

      init(repositoryProvider: RepositoryProvider) {
         set = .init(repository: repositoryProvider.getWatchlist,
                     schedulerExecutor: ImmediateSchedulerExecutor())

         get = .init(repository: repositoryProvider.getWatchlist,
                     schedulerExecutor: ImmediateSchedulerExecutor())

         peek = .init(repository: repositoryProvider.getWatchlist,
                      schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct Stream {
      /// Use case for determining if we are online.
      let unsubscribe: UnsubscribeStreamUseCaseType<UnsubscribeStreamRepository>

      init(repositoryProvider: RepositoryProvider) {
         unsubscribe = .init(repository: repositoryProvider.stream,
                             schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct PushNotification {
      /// Use case for determining if we are online.
      let register: PushNotificationRegistrationUseCaseType<PushNotificationRegistrationRepository>

      init(repositoryProvider: RepositoryProvider) {
         register = .init(repository: repositoryProvider.pushNotificationRegistration,
                          schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct Alert {
      let alerts: AlertUseCaseType<AlertRepository>
      let createAlert: CreateAlertUseCaseType<CreateAlertRepository>
      let deleteAlert: DeleteAlertUseCaseType<DeleteAlertRepository>
      let updateAlert: UpdateAlertUseCaseType<UpdateAlertRepository>

      init(repositoryProvider: RepositoryProvider) {
         alerts = .init(repository: repositoryProvider.alert,
                        schedulerExecutor: ImmediateSchedulerExecutor())
         createAlert = .init(repository: repositoryProvider.createAlert,
                             schedulerExecutor: ImmediateSchedulerExecutor())
         deleteAlert = .init(repository: repositoryProvider.deleteAlert,
                             schedulerExecutor: ImmediateSchedulerExecutor())
         updateAlert = .init(repository: repositoryProvider.updateAlert,
                             schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension UseCaseProvider {
   struct CurrencyPair {
      let getCurrencyPair: GetCurrencyPairUseCaseType<CurrencyPairRepository>

      init(repositoryProvider: RepositoryProvider) {
         getCurrencyPair = .init(repository: repositoryProvider.currencyPair,
                                 schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}
