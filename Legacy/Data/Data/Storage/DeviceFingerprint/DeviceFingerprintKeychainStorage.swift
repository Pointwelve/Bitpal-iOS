//
//  DeviceFingerprintKeychainStorage.swift
//  Data
//
//  Created by Ryne Cheow on 5/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift
import SwiftKeychainWrapper

final class DeviceFingerprintKeychainStorage: DeviceFingerprintStorage {
   typealias Object = DeviceFingerprintData
   private let keychain: KeychainWrapper

   init(keychain: KeychainWrapper = .standard) {
      self.keychain = keychain
      super.init()
   }

   override func get(_ key: String) -> Observable<DeviceFingerprintData> {
      // Unable to retrieve, create a new token
      guard let storedData = keychain.data(forKey: key) else {
         return .error(CacheError.notFound)
      }

      // Able to retrieve but undeserializable, return error
      guard let data = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: storedData) as? [String: String],
         let token = try? DeviceFingerprintData.deserialize(data: data) else {
         return Observable.error(ParseError.parseFailed)
      }

      return Observable.just(token)
   }

   override func set(_ value: DeviceFingerprintData, for key: String) -> Observable<Void> {
      return Observable<Void>.deferred {
         Observable<Void>.create { [weak self] observer in
            do {
               let data = try NSKeyedArchiver.archivedData(withRootObject: value.serialized(), requiringSecureCoding: false)
               self?.keychain.set(data, forKey: key)
               observer.onNext(())
            } catch {
               observer.onError(error)
            }
            return Disposables.create()
         }
      }
   }

   override func delete(_ key: String) -> Observable<Void> {
      keychain.removeObject(forKey: key)
      return .just(())
   }
}
