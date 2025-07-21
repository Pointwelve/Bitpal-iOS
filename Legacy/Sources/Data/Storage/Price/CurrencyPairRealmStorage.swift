//
//  CurrencyPairRealmStorage.swift
//  Data
//
//  Created by Ryne Cheow on 12/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

class CurrencyPairRealmStorage: CurrencyPairStorage {
   private let realmManager: RealmManager

   init(realmManager: RealmManager) {
      self.realmManager = realmManager
      super.init()
   }

   override func keyValues() -> Observable<[(String, CurrencyPairData)]> {
      return Observable.justTry {
         let objects: [CurrencyPairRealm] = try realmManager.list()
         return objects.map { ($0.id, $0.asData()) }
      }
   }

   override func get(_ key: String) -> Observable<CurrencyPairData> {
      return Observable.justTry { () -> CurrencyPairData in
         (try realmManager.get(with: key) as CurrencyPairRealm).asData()
      }
   }

   override func set(_ value: CurrencyPairData, for key: String) -> Observable<Void> {
      return Observable.justTry { () -> Void in
         _ = try realmManager.set(value.asRealm())
      }
   }

   override func delete(_ key: String) -> Observable<Void> {
      return Observable.justTry { () -> Void in
         let object: CurrencyPairRealm = try realmManager.get(with: key)
         _ = try realmManager.delete(object)
      }
   }
}
