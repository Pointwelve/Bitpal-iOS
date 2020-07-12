//
//  CreateAlertRepository.swift
//  Data
//
//  Created by Li Hao Lai on 19/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias CreateAlertRepositoryType = Updateable

class CreateAlertRepository: CreateAlertRepositoryType {
   typealias Key = CreateAlertRequest
   typealias Value = String

   fileprivate let cache: BasicCache<CreateAlertRequest, CreateAlertResponseData>
   fileprivate let storage: AlertListRealmStorage

   init(apiClient: APIClient, storage: AlertListRealmStorage) {
      let routerTransformer = RouterTransformer.createAlert()
      let jsonTransformer = JsonTransformer.createAlert()

      self.storage = storage
      cache = NetworkDataSource(apiClient: apiClient,
                                keyTransformer: routerTransformer,
                                valueTransformer: jsonTransformer).asBasicCache()
   }

   fileprivate func create(with alert: Alert) -> Observable<Void> {
      return storage.get(AlertList.defaultKey)
         .flatMapLatest { [weak self] list -> Observable<Void> in
            guard let `self` = self else {
               return .just(())
            }

            var newAlerts = list.alerts
            newAlerts.append(alert.asData())

            let newList = AlertListData(id: list.id, alerts: newAlerts, modifyDate: Date())
            return self.storage.set(newList, for: AlertList.defaultKey)
         }
   }
}

extension CreateAlertRepository {
   func update(_ key: CreateAlertRequest) -> Observable<String> {
      return cache.get(key)
         .flatMapLatest { [weak self] (responseData) -> Observable<String> in
            guard let `self` = self else {
               return .just(responseData.id)
            }

            let alert = Alert(id: responseData.id,
                              base: key.base,
                              quote: key.quote,
                              exchange: key.exchange,
                              comparison: key.comparison,
                              reference: key.reference,
                              isEnabled: key.isEnabled)
            return self.create(with: alert)
               .map { responseData.id }
         }
   }
}
