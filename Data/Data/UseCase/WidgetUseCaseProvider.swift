//
//  WidgetUseCaseProvider.swift
//  Data
//
//  Created by James Lai on 4/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct WidgetUseCaseProvider {
   let device: Device
   let preferences: Preferences
   let price: Price
   let watchlist: Watchlist

   init(repositoryProvider: WidgetRepositoryProvider) {
      device = .init(repositoryProvider: repositoryProvider)
      preferences = .init(repositoryProvider: repositoryProvider)
      watchlist = .init(repositoryProvider: repositoryProvider)
      price = .init(repositoryProvider: repositoryProvider)
   }
}

extension WidgetUseCaseProvider {
   struct Device {
      /// Use case for determining if we are online.
      let isOnline: IsOnlineUseCaseType<IsOnlineRepository>

      init(repositoryProvider: WidgetRepositoryProvider) {
         isOnline = .init(repository: repositoryProvider.isOnline, schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension WidgetUseCaseProvider {
   struct Preferences {
      /// Use case for reading user preferences.
      let read: ReadPreferencesUseCaseType<PreferencesRepository>
      /// Use case for writing user preferences.
      let write: WritePreferencesUseCaseType<PreferencesRepository>

      init(repositoryProvider: WidgetRepositoryProvider) {
         read = .init(repository: repositoryProvider.preferences,
                      schedulerExecutor: ImmediateSchedulerExecutor())
         write = .init(repository: repositoryProvider.preferences,
                       schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension WidgetUseCaseProvider {
   struct Price {
      /// Use case for determining if we are online.
      let getCurrencyDetail: GetCurrencyDetailUseCaseType<WidgetCurrencyDetailRepository>

      init(repositoryProvider: WidgetRepositoryProvider) {
         getCurrencyDetail = .init(repository: repositoryProvider.currencyDetail,
                                   schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}

extension WidgetUseCaseProvider {
   struct Watchlist {
      /// Use case for determining if we are online.
      let peek: PeekWatchlistUseCaseType<PeekWatchlistRepository>

      init(repositoryProvider: WidgetRepositoryProvider) {
         peek = .init(repository: repositoryProvider.watchlist,
                      schedulerExecutor: ImmediateSchedulerExecutor())
      }
   }
}
