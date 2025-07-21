//
//  CurrencyDetailRealmStorage.swift
//  Data
//
//  Created by Kok Hong Choo on 27/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift
class CurrencyDetailRealmStorage: CurrencyDetailStorage {
   private let realmManager: RealmManager

   init(realmManager: RealmManager) {
      self.realmManager = realmManager
      super.init()
   }

   override func keyValues() -> Observable<[(GetCurrencyDetailRequest, CurrencyDetailData)]> {
      return Observable.justTry {
         let objects: [CurrencyDetailRealm] = try realmManager.list()
         // Assume nil sort for default
         // Temporary calls go straight to network, therefore this should be false
         return objects.map { (GetCurrencyDetailRequest.createEmpty(), $0.asData()) }
      }
   }

   override func get(_ key: GetCurrencyDetailRequest) -> Observable<CurrencyDetailData> {
      return Observable.justTry { () -> CurrencyDetailData in
         (try realmManager.get(with: key.primaryKey) as CurrencyDetailRealm).asData()
      }
   }

   override func delete(_ key: GetCurrencyDetailRequest) -> Observable<Void> {
      return Observable.justTry {
         let object: CurrencyDetailRealm = try realmManager.get(with: key.primaryKey)
         try realmManager.delete(object)
         return ()
      }
   }

   override func set(_ value: CurrencyDetailData, for key: GetCurrencyDetailRequest) -> Observable<Void> {
      return Observable.justTry { () -> Void in
         _ = try realmManager.set(value.asRealm()).asData()
      }
   }
}
