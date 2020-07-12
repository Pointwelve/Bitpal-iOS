//
//  RepositoryType.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public protocol RepositoryType {}

public protocol AppRepositoryType: RepositoryType {
   var prices: AppPricesUseCaseCoordinatorContainerType { get }
   var device: DeviceUseCaseCoordinatorContainerType { get }
   var deviceFingerprint: DeviceFingerprintUseCaseCoordinatorContainerType { get }
   var preferences: PreferencesUseCaseCoordinatorContainerType { get }
   var user: UserUseCaseCoordinatorContainerType { get }
   var stream: StreamUseCaseCoordinatorContainerType { get }
   var pushNotification: PushNotificationUseCaseCoordinatorContainerType { get }
   var watchlist: WatchlistUseCaseCoordinatorContainerType { get }
   var alert: AlertUseCaseCoordinatorContainerType { get }
   var currencyPair: CurrencyPairUseCaseCoordinatorContainerType { get }
}

public protocol PricesUseCaseCoordinatorContainerType {
   func currencyDetail(request: GetCurrencyDetailRequest) -> CurrencyDetailUseCaseCoordinator
}

public protocol AppPricesUseCaseCoordinatorContainerType: PricesUseCaseCoordinatorContainerType {
   func currencyPairList() -> CurrencyPairListUseCaseCoordinator
   func streamPrice(request: GetPriceListRequest) -> StreamPriceUseCaseCoordinator
   func historicalPrice(request: HistoricalPriceListRequest) -> HistoricalPriceListUseCaseCoordinator
}

public protocol DeviceUseCaseCoordinatorContainerType {
   func isOnline() -> IsOnlineUseCaseCoordinator
}

public protocol DeviceFingerprintUseCaseCoordinatorContainerType {
   func read() -> DeviceFingerprintUseCaseCoordinator
   func peek() -> DeviceFingerprintUseCaseCoordinator
   func delete() -> DeviceFingerprintDeleteUseCaseCoordinator
}

public protocol PreferencesUseCaseCoordinatorContainerType {
   func preferences(existing: Domain.Preferences,
                    preferredLanguageAction: @escaping () -> Language,
                    preferredThemeAction: @escaping () -> Theme,
                    preferredChartTypeAction: @escaping () -> ChartType) -> PreferencesUseCaseCoordinator
}

public protocol WidgetPreferencesUseCaseCoordinatorContainerType {
   func preferences(existing: Domain.Preferences) -> WidgetPreferenceUseCaseCoordinator
}

public protocol WidgetWatchlistUseCaseCoordinatorContainerType {
   func watchlist() -> PeekWatchlistUseCaseCoordinator
}

public protocol UserUseCaseCoordinatorContainerType {
   func userIdentifier() -> UserIdentifierUseCaseCoordinator
   func authenticate() -> AuthenticationUseCaseCoordinator
   func anonymousMigration(with request: AnonymousMigrationRequest)
      -> AnonymousMigrationUseCaseCoordinator
   func setSkipUserMigration(value: Bool) -> SetSkipUserMigrationUseCaseCoordinator
   func peekSkipUserMigration() -> PeekSkipUserMigrationUseCaseCoordinator
}

public protocol WatchlistUseCaseCoordinatorContainerType {
   func peekWatchlist() -> PeekWatchlistUseCaseCoordinator
   func writeWatchlist(request: SetWatchlistRequest) -> SetWatchlistUseCaseCoordinator
   func watchlist() -> GetWatchlistUseCaseCoordinator
}

public protocol StreamUseCaseCoordinatorContainerType {
   func unsubscribe() -> StreamUseCaseCoordinator
}

public protocol PushNotificationUseCaseCoordinatorContainerType {
   func register(token: String) -> PushNotificationUseCaseCoordinator
}

public protocol AlertUseCaseCoordinatorContainerType {
   func alerts() -> AlertUseCaseCoordinator
   func createAlert(request: CreateAlertRequest) -> CreateAlertUseCaseCoordinator
   func deleteAlert(request: String) -> DeleteAlertUseCaseCoordinator
   func updateAlert(request: Alert) -> UpdateAlertUseCaseCoordinator
}

public protocol CurrencyPairUseCaseCoordinatorContainerType {
   func getCurrecnyPair(request: String) -> GetCurrencyPairUseCaseCoordinator
}
