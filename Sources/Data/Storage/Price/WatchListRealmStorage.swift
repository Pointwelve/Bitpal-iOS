//
//  CurrencyPairRealmStorage.swift
//  Data
//
//  Created by Hong on 26/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

class WatchlistRealmStorage: WatchlistStorage {
   private let realmManager: RealmManager

   init(realmManager: RealmManager) {
      self.realmManager = realmManager
      super.init()
   }

   override func keyValues() -> Observable<[(String, WatchlistData)]> {
      return Observable.justTry {
         let objects: [WatchListRealm] = try realmManager.list()
         return objects.map { (Watchlist.defaultKey, $0.asData()) }
      }
   }

   override func get(_ key: String) -> Observable<WatchlistData> {
      return Observable.justTry { () -> WatchlistData in
         (try realmManager.get(with: key) as WatchListRealm).asData()
      }
   }

   override func delete(_ key: String) -> Observable<Void> {
      return Observable.justTry {
         let object: WatchListRealm = try realmManager.get(with: key)
         try realmManager.delete(object)
      }
   }

   override func set(_ value: WatchlistData, for key: String) -> Observable<Void> {
      return Observable.justTry { () -> Void in
         _ = try realmManager.set(value.asRealm())
      }
   }
}
