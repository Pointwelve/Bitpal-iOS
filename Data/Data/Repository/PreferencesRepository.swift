//
//  PreferencesRepository.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias PreferencesRepositoryType = Readable & Writeable

class PreferencesRepository: PreferencesRepositoryType {
   typealias Key = Void
   typealias Value = Preferences

   fileprivate let defaultKey = "default"
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<PreferencesData, Preferences>
   fileprivate let storage: PreferencesStorage

   init(target: Target = .app, storage: PreferencesStorage? = nil) {
      self.storage = storage ?? PreferencesUserDefaultsStorage(target: target)
      entityTransformer = DomainTransformer.preferences()
   }

   func read() -> Observable<Preferences> {
      return storage
         .get(defaultKey)
         .flatMap(entityTransformer.transform)
   }

   func write(_ value: Value) -> Observable<Value> {
      return entityTransformer
         .transform(value)
         .flatMap { value -> Observable<Void> in
            self.storage.set(value, for: self.defaultKey)
         }
         .flatMap { _ -> Observable<Preferences> in
            self.read()
         }
   }
}
