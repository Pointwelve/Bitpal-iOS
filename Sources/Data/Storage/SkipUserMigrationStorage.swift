//
//  SkipUserMigrationStorage.swift
//  Data
//
//  Created by Li Hao Lai on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift
import SwiftKeychainWrapper

final class SkipUserMigrationStorage: SkipMigrationStorage {
   typealias Object = Bool
   private let keychain: KeychainWrapper

   init(keychain: KeychainWrapper = .standard) {
      self.keychain = keychain
      super.init()
   }

   override func get(_ key: String) -> Observable<Bool> {
      guard let flag = keychain.bool(forKey: key) else {
         return .error(CacheError.notFound)
      }
      return .just(flag)
   }

   override func set(_ value: Bool, for key: String) -> Observable<Void> {
      keychain.set(value, forKey: key)
      return .just(())
   }

   override func delete(_ key: String) -> Observable<Void> {
      keychain.removeObject(forKey: key)
      return .just(())
   }
}
