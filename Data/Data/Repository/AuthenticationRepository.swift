//
//  AuthenticationRepository.swift
//  Data
//
//  Created by Ryne Cheow on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import CloudKit
import Domain
import Foundation
import RxSwift

typealias AuthenticationRepositoryType = Readable

class AuthenticationRepository: AuthenticationRepositoryType {
   typealias Key = Void
   typealias Value = UserType

   fileprivate let api: BasicCache<String, AuthenticationTokenData>
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<AuthenticationTokenData, AuthenticationToken>

   fileprivate let iCloudIdentifierStorage: IdentifierStorage
   fileprivate let anonymousIdentifierStorage: DeviceFingerprintStorage
   fileprivate let anonymousIdentifierGenerator: DeviceFingerprintStorage
   fileprivate let skipUserMigrationStorage: SkipUserMigrationStorage

   fileprivate let firebaseAuthenticator: (AuthenticationToken) -> Observable<UserType>

   init(apiClient: APIClient,
        firebaseAuthenticator: @escaping (AuthenticationToken) -> Observable<UserType>,
        iCloudIdentifierStorage: IdentifierStorage = IdentifieriCloudStorage(),
        anonymousIdentifierStorage: DeviceFingerprintStorage = DeviceFingerprintKeychainStorage(),
        anonymousIdentifierGenerator: DeviceFingerprintStorage = DeviceFingerprintGenerator(),
        skipUserMigrationStorage: SkipUserMigrationStorage = SkipUserMigrationStorage()) {
      api = NetworkDataSource(apiClient: apiClient,
                              keyTransformer: RouterTransformer.authenticationToken(),
                              valueTransformer: JsonTransformer.authenticationToken()).asBasicCache()
      entityTransformer = DomainTransformer.authenticationToken()

      self.iCloudIdentifierStorage = iCloudIdentifierStorage
      self.anonymousIdentifierStorage = anonymousIdentifierStorage
      self.skipUserMigrationStorage = skipUserMigrationStorage
      self.anonymousIdentifierGenerator = anonymousIdentifierGenerator
      self.firebaseAuthenticator = firebaseAuthenticator
   }
}

extension AuthenticationRepository {
   func read() -> Observable<UserType> {
      let anonIdentifierRetriever = anonymousIdentifierStorage
         .get(DeviceFingerprintRepository.defaultKey)
         .catchError { [unowned self] error -> Observable<DeviceFingerprintData> in
            /// 2. If flag not found proceed to retrieve iCloud ID
            switch error {
            case CacheError.notFound:
               return self.anonymousIdentifierGenerator
                  .get(DeviceFingerprintRepository.defaultKey)
                  .flatMap { key in
                     self.anonymousIdentifierStorage
                        .set(key, for: DeviceFingerprintRepository.defaultKey)
                        .flatMap { Observable.just(key) }
                  }
            default:
               return .error(error)
            }
         }
         .map { $0.data }

      let usualIdentifierRetriever = iCloudIdentifierStorage.get("")
         .catchError { error -> Observable<String> in
            switch error {
            case CKError.notAuthenticated, CloudServiceError.unauthorized:
               return anonIdentifierRetriever
            default:
               return .error(error)
            }
         }

      // 1. Check if has SKIP migration flag
      let identifierRetriever = skipUserMigrationStorage.get(SkipUserMigrationRepository.defaultKey)
         .map { _ in "" } // Disregard value as value containment implies flag existence
         .flatMap { _ in anonIdentifierRetriever } // 3. Flag found, just retrieve anonymous ID
         .catchError { error -> Observable<String> in
            // 2. If flag not found proceed to retrieve iCloud ID
            switch error {
            case CacheError.notFound:
               return usualIdentifierRetriever
            default:
               return .error(error)
            }
         }

      return identifierRetriever
         .flatMap(api.get)
         .flatMap(entityTransformer.transform)
         .flatMap(firebaseAuthenticator)
   }
}
