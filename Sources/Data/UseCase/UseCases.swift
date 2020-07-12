//
//  UseCase.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

/// Use case for reading app configuration.

class ReadConfigurationUseCaseType<T: ConfigurationRepositoryType>: UseCase<T>, Readable {}

/// Use case for determining if we are online.

class IsOnlineUseCaseType<T: IsOnlineRepositoryType>: UseCase<T>, Readable {}

/// Use case for reading and writing user preferences.

class ReadPreferencesUseCaseType<T: PreferencesRepositoryType>: UseCase<T>, Readable {}

/// Use case for reading and writing user preferences.

class WritePreferencesUseCaseType<T: PreferencesRepositoryType>: UseCase<T>, Writeable {}

/// Use case for streaming the latest price list.
class StreamLatestPriceUseCaseType<T: StreamPriceRepositoryType>: UseCase<T>, Streamable {}

/// Use case for getting an iCloud ID.
// swiftlint:disable type_name
class iCloudIdentifierUseCaseType<T: IdentifierRepository>: UseCase<T>, Readable {}

/// Use case for getting historical price list
class GetHistoricalPriceListUseCaseType<T: HistoricalPriceListRepositoryType>: UseCase<T>, Gettable {}

/// Use case for setting watchlist
class SetWatchlistUseCaseType<T: WatchlistRepositoryType>: UseCase<T>, Gettable {}

/// Use case for getting watchlist
class GetWatchlistUseCaseType<T: WatchlistRepositoryType>: UseCase<T>, Readable {}

/// Use case for peeking stored watchlist
class PeekWatchlistUseCaseType<T: PeekWatchlistRepositoryType>: UseCase<T>, Peekable {}

/// Use case for unsubscribing subscription
class UnsubscribeStreamUseCaseType<T: UnsubscribeStreamRepository>: UseCase<T>, Readable {}

/// Use case for get price full
class GetCurrencyDetailUseCaseType<T: CurrencyDetailRepositoryType>: UseCase<T>, Gettable {}

/// Use case for getting price list
class CurrencyPairListUseCaseType<T: CurrencyPairListRepositoryType>: UseCase<T>, Gettable {}

/// Use case for authentication exchange
class AuthenticationUseCaseType<T: AuthenticationRepository>: UseCase<T>, Readable {}

/// Use case for generating device fingerprint
class ReadDeviceFingerprintUseCaseType<T: DeviceFingerprintRepository>: UseCase<T>, Readable {}

/// Use case for registering push notification token
class PushNotificationRegistrationUseCaseType<T: PushNotificationRegistrationRepository>: UseCase<T>, Gettable {}

/// Use case for peeking device fingerprint
class PeekDeviceFingerprintUseCaseType<T: DeviceFingerprintRepository>: UseCase<T>, Peekable {}

/// Use case for deleting device fingerprint
class DeleteDeviceFingerprintUseCaseType<T: DeviceFingerprintRepository>: UseCase<T>, Deletable {}

/// Use case for anonymous user migrate to iCloud user
class AnonymousMigrationUseCaseType<T: AnonymousMigrationRepositoryType>: UseCase<T>, Updateable {}

/// Use case for setting Skip user migration
class SetSkipUserMigrationUseCaseType<T: SkipUserMigrationRepositoryType>: UseCase<T>, Settable {}

/// Use case for peeking Skip user migration
class PeekSkipUserMigrationUseCaseType<T: SkipUserMigrationRepositoryType>: UseCase<T>, Peekable {}

/// Use case for getting User's alert
class AlertUseCaseType<T: AlertRepository>: UseCase<T>, Gettable {}

/// Use case for creating new Alert
class CreateAlertUseCaseType<T: CreateAlertRepository>: UseCase<T>, Updateable {}

/// Use case for deleting Alert
class DeleteAlertUseCaseType<T: DeleteAlertRepository>: UseCase<T>, Deletable {}

/// Use case for updateing Alert
class UpdateAlertUseCaseType<T: UpdateAlertRepository>: UseCase<T>, Updateable {}

/// Use case for getting CurrencyPair
class GetCurrencyPairUseCaseType<T: CurrencyPairRepository>: UseCase<T>, Gettable {}
