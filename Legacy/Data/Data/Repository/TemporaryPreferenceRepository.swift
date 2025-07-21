//
//  TemporaryPreferenceRepository.swift
//  Data
//
//  Created by Ryne Cheow on 10/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

class TemporaryPreferencesRepository: PreferencesRepository {
   private let preferences: Value

   init(theme: Theme, language: Language) {
      preferences = Preferences(language: language, theme: theme)
   }

   override func read() -> Observable<Preferences> {
      return .just(preferences)
   }

   override func write(_ value: Preferences) -> Observable<Preferences> {
      return .error(CacheError.invalid)
   }
}
