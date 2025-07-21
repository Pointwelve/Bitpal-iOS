//
//  AlertListRealmStorage.swift
//  Data
//
//  Created by James Lai on 23/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RealmSwift
import RxSwift

final class AlertListRealmStorage: AlertListStorage {
   private let realmManager: RealmManager

   init(realmManager: RealmManager) {
      self.realmManager = realmManager
      super.init()
   }

   override func keyValues() -> Observable<[(String, AlertListData)]> {
      return Observable.justTry {
         let objects: [AlertListRealm] = try realmManager.list()
         return objects.map { (AlertList.defaultKey, $0.asData()) }
      }
   }

   override func get(_ key: String) -> Observable<AlertListData> {
      return Observable.justTry { () -> AlertListData in
         (try realmManager.get(with: key) as AlertListRealm).asData()
      }
   }

   override func delete(_ key: String) -> Observable<Void> {
      return Observable.justTry {
         let object: AlertListRealm = try realmManager.get(with: key)
         try realmManager.delete(object)
      }
   }

   override func set(_ value: AlertListData, for key: String) -> Observable<Void> {
      return Observable.justTry { () -> Void in
         _ = try realmManager.set(value.asRealm())
      }
   }
}
