//
//  PreferencesUserDefaultsStorage.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

final class PreferencesUserDefaultsStorage: PreferencesStorage {
   typealias Object = PreferencesData
   private let userDefaults: UserDefaults
   private let target: Target

   init(userDefaults: UserDefaults = UserDefaults(suiteName: "group.com.pointwelve.app.bitpal") ?? .standard,
        target: Target = .app) {
      self.userDefaults = userDefaults
      self.target = target
      super.init()
   }

   override func get(_ key: String) -> Observable<PreferencesData> {
      guard let data = userDefaults.value(forKey: key) as? [String: Any],
         let preferences = try? PreferencesData.deserialize(data: data) else {
         guard let preferences = migration(key) else {
            return Observable<PreferencesData>.error(ParseError.parseFailed)
         }
         return Observable.just(preferences)
      }
      return Observable.just(preferences)
   }

   override func set(_ value: PreferencesData, for key: String) -> Observable<Void> {
      // Prevent Widget override preference
      if target == .app {
         userDefaults.set(value.serialized(), forKey: key)
         userDefaults.synchronize()
      }

      return Observable.just(())
   }

   /// Remove this migration function after all users upgrade to 1.3
   private func migration(_ key: String) -> PreferencesData? {
      let userDefaults = UserDefaults.standard

      guard let data = userDefaults.value(forKey: key) as? [String: Any],
         let preferences = try? PreferencesData.deserialize(data: data) else {
         return nil
      }

      _ = set(preferences, for: key)

      return preferences
   }
}
