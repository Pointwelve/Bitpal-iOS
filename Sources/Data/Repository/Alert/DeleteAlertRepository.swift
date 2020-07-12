//
//  DeleteAlertRepository.swift
//  Data
//
//  Created by Li Hao Lai on 24/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias DeleteAlertRepositoryType = Deletable

final class DeleteAlertRepository: DeleteAlertRepositoryType {
   typealias Key = String
   typealias Value = Void

   fileprivate let cache: BasicCache<String, StandardResponseData>
   fileprivate let storage: AlertListRealmStorage

   init(apiClient: APIClient, storage: AlertListRealmStorage) {
      let routerTransformer = RouterTransformer.deleteAlert()
      let jsonTransformer = JsonTransformer.standardResponse()

      self.storage = storage
      cache = NetworkDataSource(apiClient: apiClient,
                                keyTransformer: routerTransformer,
                                valueTransformer: jsonTransformer).asBasicCache()
   }

   fileprivate func delete(with key: String) -> Observable<Void> {
      return storage.get(AlertList.defaultKey)
         .flatMapLatest { [weak self] list -> Observable<Void> in
            guard let `self` = self else {
               return .just(())
            }

            let newAlerts = list.alerts.filter { $0.id != key }
            let newList = AlertListData(id: list.id, alerts: newAlerts, modifyDate: Date())

            return self.storage.set(newList, for: AlertList.defaultKey)
         }
   }
}

extension DeleteAlertRepository {
   func delete(_ key: String) -> Observable<Void> {
      return cache.get(key)
         .flatMapLatest { [weak self] _ -> Observable<Void> in
            guard let `self` = self else {
               return .just(())
            }

            return self.delete(with: key)
         }
   }
}
