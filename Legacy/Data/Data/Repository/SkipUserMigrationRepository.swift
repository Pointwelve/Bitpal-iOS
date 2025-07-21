//
//  SkipUserMigrationRepository.swift
//  Data
//
//  Created by Li Hao Lai on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias SkipUserMigrationRepositoryType = Settable & Peekable

final class SkipUserMigrationRepository: SkipUserMigrationRepositoryType {
   typealias Key = String
   typealias Value = Bool

   static let defaultKey = "skipUserMigration"
   fileprivate let storage: SkipUserMigrationStorage

   init(storage: SkipUserMigrationStorage = SkipUserMigrationStorage()) {
      self.storage = storage
   }
}

extension SkipUserMigrationRepository {
   func set(_ value: Bool, for key: String) -> Observable<Bool> {
      return storage.set(value, for: SkipUserMigrationRepository.defaultKey)
         .map { value }
   }

   func peek() -> Observable<Bool> {
      return storage.get(SkipUserMigrationRepository.defaultKey)
   }
}
