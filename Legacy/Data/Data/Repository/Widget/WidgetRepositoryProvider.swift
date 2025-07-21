//
//  WidgetRepositoryProvider.swift
//  Data
//
//  Created by Li Hao Lai on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

final class WidgetRepositoryProvider: RepositoryProviderType {
   let apiClient: APIClient
   let realmManager: RealmManager

   let preferences: PreferencesRepository
   let isOnline: IsOnlineRepository
   let watchlist: PeekWatchlistRepository
   let currencyDetail: WidgetCurrencyDetailRepository

   init(apiClient: APIClient,
        preferencesRepository: PreferencesRepository,
        realmManager: RealmManager,
        onMemoryWarning: Observable<Void>) {
      self.realmManager = realmManager
      self.apiClient = apiClient

      preferences = preferencesRepository
      isOnline = IsOnlineRepository()

      let watchListStorage = WatchlistRealmStorage(realmManager: realmManager)
      watchlist = PeekWatchlistRepository(storage: watchListStorage)

      currencyDetail = WidgetCurrencyDetailRepository(apiClient: apiClient)
   }
}
