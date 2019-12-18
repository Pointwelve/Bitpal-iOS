//
//  RepositoryProvider.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

protocol RepositoryProviderType {
   var apiClient: APIClient { get }

   var realmManager: RealmManager { get }

   var preferences: PreferencesRepository { get }

   var isOnline: IsOnlineRepository { get }
}

final class RepositoryProvider: RepositoryProviderType {
   let apiClient: APIClient
   let functionsClient: APIClient
   let socketClient: SocketClient
   let realmManager: RealmManager

   let preferences: PreferencesRepository
   let isOnline: IsOnlineRepository
   let streamPrice: StreamPriceRepository
   let historicalPriceList: HistoricalPriceListRepository
   let iCloudIdentifier: IdentifierRepository
   let stream: UnsubscribeStreamRepository
   let currencyDetail: CurrencyDetailRepository
   let currencyPairList: CurrencyPairListRepository
   let authentication: AuthenticationRepository
   let getWatchlist: WatchlistRepository
   let pushNotificationRegistration: PushNotificationRegistrationRepository
   let deviceFingerprint: DeviceFingerprintRepository
   let anonymousMigration: AnonymousMigrationRepository
   let skipUserMigration: SkipUserMigrationRepository
   let alert: AlertRepository
   let createAlert: CreateAlertRepository
   let deleteAlert: DeleteAlertRepository
   let updateAlert: UpdateAlertRepository
   let currencyPair: CurrencyPairRepository

   init(apiClient: APIClient,
        functionsClient: APIClient,
        socketClient: SocketClient,
        firebaseAuthProvider: FirebaseAuthProviderType,
        preferencesRepository: PreferencesRepository,
        realmManager: RealmManager,
        onMemoryWarning: Observable<Void>,
        onAppEnteredBackground: Observable<Void>,
        onAppEnteredForeground: Observable<Void>,
        onAppWillTerminate: Observable<Void>) {
      self.realmManager = realmManager
      self.functionsClient = functionsClient
      self.apiClient = apiClient
      self.socketClient = socketClient

      preferences = preferencesRepository
      isOnline = IsOnlineRepository()

      let pricelistStorage = CurrencyPairListRealmStorage(realmManager: realmManager)
      currencyPairList = CurrencyPairListRepository(apiClient: functionsClient, storage: pricelistStorage)

      let currenciesStorage = CurrenciesRealmStorage(realmManager: realmManager)

      streamPrice = StreamPriceRepository(socketClient: socketClient, currenciesStorage: currenciesStorage)

      let historicalPriceListRealmStorage = HistoricalPriceListRealmStorage(realmManager: realmManager)
      historicalPriceList =
         HistoricalPriceListRepository(apiClient: apiClient,
                                       storage: historicalPriceListRealmStorage,
                                       currenciesStorage: currenciesStorage)
      iCloudIdentifier = IdentifierRepository()

      let watchListStorage = WatchlistRealmStorage(realmManager: realmManager)
      stream = UnsubscribeStreamRepository(socketClient: socketClient)
      let currencyDetailStorage = CurrencyDetailRealmStorage(realmManager: realmManager)
      currencyDetail = CurrencyDetailRepository(apiClient: apiClient, storage: currencyDetailStorage)

      authentication = AuthenticationRepository(apiClient: functionsClient,
                                                firebaseAuthenticator: firebaseAuthProvider.authenticate)

      getWatchlist = WatchlistRepository(apiClient: functionsClient,
                                         watchlistStorage: watchListStorage)

      deviceFingerprint = DeviceFingerprintRepository()
      pushNotificationRegistration = PushNotificationRegistrationRepository(apiClient: functionsClient)
      anonymousMigration = AnonymousMigrationRepository(apiClient: functionsClient)
      skipUserMigration = SkipUserMigrationRepository()

      let alertListStorage = AlertListRealmStorage(realmManager: realmManager)
      alert = AlertRepository(apiClient: functionsClient, storage: alertListStorage)
      createAlert = CreateAlertRepository(apiClient: functionsClient, storage: alertListStorage)
      deleteAlert = DeleteAlertRepository(apiClient: functionsClient, storage: alertListStorage)
      updateAlert = UpdateAlertRepository(apiClient: functionsClient, storage: alertListStorage)

      let currencyPairStorage = CurrencyPairRealmStorage(realmManager: realmManager)
      currencyPair = CurrencyPairRepository(storage: currencyPairStorage)
   }
}
