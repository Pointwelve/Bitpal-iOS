//
//  DeviceFingerprintRepository.swift
//  Data
//
//  Created by Alvin Choo on 3/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias DeviceFingerprintRepositoryType = Readable & Peekable & Deletable

final class DeviceFingerprintRepository: DeviceFingerprintRepositoryType {
   typealias Key = String
   typealias Value = String

   static let defaultKey = "deviceFingerprint"
   fileprivate let cache: BasicCache<String, DeviceFingerprintData>
   fileprivate let storage: DeviceFingerprintStorage

   init(storage: DeviceFingerprintStorage = DeviceFingerprintKeychainStorage(),
        generator: DeviceFingerprintStorage = DeviceFingerprintGenerator()) {
      self.storage = storage
      cache = storage + generator
   }
}

extension DeviceFingerprintRepository {
   func read() -> Observable<String> {
      return cache.get(DeviceFingerprintRepository.defaultKey)
         .map {
            $0.data
         }
   }

   func peek() -> Observable<String> {
      return storage.get(DeviceFingerprintRepository.defaultKey)
         .map {
            $0.data
         }
   }

   func delete(_ key: String) -> Observable<String> {
      return storage.delete(DeviceFingerprintRepository.defaultKey)
         .map { key }
   }
}
