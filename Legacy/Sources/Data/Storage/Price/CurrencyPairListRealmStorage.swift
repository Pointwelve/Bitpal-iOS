//
//  PriceListRealmStorage.swift
//  Data
//
//  Created by Li Hao Lai on 17/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

class CurrencyPairListRealmStorage: CurrencyPairListStorage {
   private let realmManager: RealmManager

   init(realmManager: RealmManager) {
      self.realmManager = realmManager
      super.init()
   }

   override func keyValues() -> Observable<[(String, CurrencyPairListData)]> {
      return Observable.justTry { // () -> (Element) in
         let objects: [CurrencyPairListRealm] = try realmManager.list()

         return objects.map { ("", $0.asData()) }
      }
   }

   override func get(_ key: String) -> Observable<CurrencyPairListData> {
      return Observable.justTry { () -> CurrencyPairListData in
         let realmObject: CurrencyPairListRealm = try realmManager.get(with: key)
         return realmObject.asData()
      }
   }

   override func delete(_ key: String) -> Observable<Void> {
      return Observable.justTry {
         let object: CurrencyPairListRealm = try realmManager.get(with: key)
         try realmManager.delete(object)
         return ()
      }
   }

   override func set(_ value: CurrencyPairListData, for key: String) -> Observable<Void> {
      return Observable.justTry { [weak self] () throws -> Void in
         guard let `self` = self else {
            return
         }
         let manager = self.realmManager

         let object = value.asRealm()
         object.modifyDate = Date()

         _ = try manager.set(object)
      }
   }
}
