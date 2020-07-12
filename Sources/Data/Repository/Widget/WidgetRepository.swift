//
//  WidgetRepository.swift
//  Data
//
//  Created by James Lai on 4/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

public protocol WidgetRepositoryType: RepositoryType {
   var device: DeviceUseCaseCoordinatorContainerType { get }
   var prices: PricesUseCaseCoordinatorContainerType { get }
   var preferences: WidgetPreferencesUseCaseCoordinatorContainerType { get }
   var watchlist: WidgetWatchlistUseCaseCoordinatorContainerType { get }
}

public struct WidgetRepository: WidgetRepositoryType {
   internal let provider: WidgetRepositoryProvider

   public let prices: PricesUseCaseCoordinatorContainerType
   public let watchlist: WidgetWatchlistUseCaseCoordinatorContainerType
   public let device: DeviceUseCaseCoordinatorContainerType
   public let preferences: WidgetPreferencesUseCaseCoordinatorContainerType

   init(provider: WidgetRepositoryProvider) {
      let useCaseProvider = WidgetUseCaseProvider(repositoryProvider: provider)
      self.provider = provider
      prices = Prices(useCaseProvider: useCaseProvider)
      watchlist = Watchlist(useCaseProvider: useCaseProvider)
      device = Device(useCaseProvider: useCaseProvider)
      preferences = Preferences(useCaseProvider: useCaseProvider)
   }
}

extension WidgetRepository {
   public struct Prices: PricesUseCaseCoordinatorContainerType {
      internal let useCaseProvider: WidgetUseCaseProvider

      private var _price: WidgetUseCaseProvider.Price {
         return useCaseProvider.price
      }

      public func currencyDetail(request: GetCurrencyDetailRequest) -> CurrencyDetailUseCaseCoordinator {
         return .init(request: request, getAction: _price.getCurrencyDetail.get)
      }
   }
}

extension WidgetRepository {
   public struct Device: DeviceUseCaseCoordinatorContainerType {
      internal let useCaseProvider: WidgetUseCaseProvider

      public func isOnline() -> IsOnlineUseCaseCoordinator {
         return .init(getAction: useCaseProvider.device.isOnline.read)
      }
   }
}

extension WidgetRepository {
   public struct Watchlist: WidgetWatchlistUseCaseCoordinatorContainerType {
      internal let useCaseProvider: WidgetUseCaseProvider

      private var _watchlist: WidgetUseCaseProvider.Watchlist {
         return useCaseProvider.watchlist
      }

      public func watchlist() -> PeekWatchlistUseCaseCoordinator {
         return .init(readAction: _watchlist.peek.peek)
      }
   }
}

extension WidgetRepository {
   public struct Preferences: WidgetPreferencesUseCaseCoordinatorContainerType {
      internal let useCaseProvider: WidgetUseCaseProvider

      private var _preferences: WidgetUseCaseProvider.Preferences {
         return useCaseProvider.preferences
      }

      public func preferences(existing: Domain.Preferences)
         -> WidgetPreferenceUseCaseCoordinator {
         return .init(preferences: existing,
                      readAction: _preferences.read.read,
                      writeAction: _preferences.write.write)
      }
   }
}
