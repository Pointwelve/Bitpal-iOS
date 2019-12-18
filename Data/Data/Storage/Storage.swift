//
//  Storage.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

// Clean architecture states that implementation details should live outside of the inner layers (Domain/Data)
// therefore these are just base classes / abstractions that the App should inject an implementation for.

/// The `ConfigurationStorage` represents an empty configuration storage implementation that must be subclassed.

class ConfigurationStorage: FailingCache<String, ConfigurationData> {
   override init() {
      super.init()
   }

   open override func set(_ value: ConfigurationData, for key: String) -> Observable<Void> {
      return .empty()
   }
}

/// The `PreferencesStorage` represents an empty user preferences storage implementation that must be subclassed.
typealias PreferencesStorage = FailingCache<String, PreferencesData>

/// The `HistroicalPriceListStorage`
typealias HistoricalPriceListStorage = FailingCache<HistoricalPriceListRequest, HistoricalPriceListData>
/// The `subclassed` represents an empty user preferences storage implementation that must be subclassed.
typealias IdentifierStorage = FailingCache<String, String>
/// Watchlist Realm Storage
typealias WatchlistStorage = FailingCache<String, WatchlistData>
/// Currencies Realm Storage
typealias CurrenciesStorage = FailingCache<String, CurrencyData>
/// Currency Pair Realm Storage
typealias CurrencyPairStorage = FailingCache<String, CurrencyPairData>

/// CurrencyPair List Realm Storage
typealias CurrencyPairListStorage = FailingCache<String, CurrencyPairListData>
typealias CurrencyPairGroupStorage = FailingCache<String, CurrencyPairGroupData>

/// Currency Detail Realm Storage
typealias CurrencyDetailStorage = FailingCache<GetCurrencyDetailRequest, CurrencyDetailData>
/// Device Fingerprint Storage
typealias DeviceFingerprintStorage = FailingCache<String, DeviceFingerprintData>
/// Skip migration storage
typealias SkipMigrationStorage = FailingCache<String, Bool>

/// Alert List Realm Storage
typealias AlertListStorage = FailingCache<String, AlertListData>
