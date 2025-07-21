//
//  UpdateAlertRepository.swift
//  Data
//
//  Created by Li Hao Lai on 26/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias UpdateAlertRepositoryType = Updateable

final class UpdateAlertRepository: UpdateAlertRepositoryType {
   typealias Key = Alert
   typealias Value = Void

   fileprivate let cache: BasicCache<Alert, UpdateAlertResponseData>
   fileprivate let storage: AlertListStorage

   init(apiClient: APIClient, storage: AlertListStorage) {
      let routerTransformer = RouterTransformer.updateAlert()
      let jsonTransformer = JsonTransformer.updateAlert()

      self.storage = storage
      cache = NetworkDataSource(apiClient: apiClient,
                                keyTransformer: routerTransformer,
                                valueTransformer: jsonTransformer).asBasicCache()
   }

   fileprivate func update(with updatedAlert: AlertData) -> Observable<Void> {
      return storage.get(AlertList.defaultKey)
         .flatMapLatest { [weak self] list -> Observable<Void> in
            guard let `self` = self else {
               return .just(())
            }

            var newAlerts = list.alerts
            for i in newAlerts.indices where newAlerts[i].id == updatedAlert.id {
               newAlerts[i] = updatedAlert
            }

            let newList = AlertListData(id: list.id, alerts: newAlerts, modifyDate: Date())

            return self.storage.set(newList, for: AlertList.defaultKey)
         }
   }
}

extension UpdateAlertRepository {
   func update(_ key: Alert) -> Observable<Void> {
      return cache.get(key)
         .map { _ in key.asData() }
         .flatMapLatest { [weak self] alert -> Observable<Void> in
            guard let `self` = self else {
               return .just(())
            }

            return self.update(with: alert)
         }
   }
}
