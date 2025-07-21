//
//  HistoricalPriceListRealmStorage.swift
//  Data
//
//  Created by Li Hao Lai on 17/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

class HistoricalPriceListRealmStorage: HistoricalPriceListStorage {
   private let realmManager: RealmManager

   init(realmManager: RealmManager) {
      self.realmManager = realmManager
      super.init()
   }

   override func keyValues() -> Observable<[(HistoricalPriceListRequest, HistoricalPriceListData)]> {
      return Observable.justTry {
         let objects: [HistoricalPriceListRealm] = try realmManager.list()
         // Assume nil sort for default
         // Temporary calls go straight to network, therefore this should be false
         return objects.map { (HistoricalPriceListRequest.createEmpty(), $0.asData()) }
      }
   }

   override func get(_ key: HistoricalPriceListRequest) -> Observable<HistoricalPriceListData> {
      return Observable.justTry { () -> HistoricalPriceListData in
         (try realmManager.get(with: key.primaryKey) as HistoricalPriceListRealm).asData()
      }
   }

   override func delete(_ key: HistoricalPriceListRequest) -> Observable<Void> {
      return Observable.justTry {
         let object: HistoricalPriceListRealm = try realmManager.get(with: key.primaryKey)
         try realmManager.delete(object)
         return ()
      }
   }

   override func set(_ value: HistoricalPriceListData, for key: HistoricalPriceListRequest) -> Observable<Void> {
      return Observable.justTry { () -> Void in
         _ = try realmManager.set(value.asRealm()).asData()
      }
   }
}
