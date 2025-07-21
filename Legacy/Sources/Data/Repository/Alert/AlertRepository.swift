//
//  AlertRepository.swift
//  Data
//
//  Created by Li Hao Lai on 17/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

typealias AlertRepositoryType = Gettable

class AlertRepository: AlertRepositoryType {
   typealias Key = String
   typealias Value = AlertList

   fileprivate let entityTransformer: BidirectionalValueTransformerBox<AlertListData, AlertList>
   fileprivate let cache: BasicCache<String, AlertListData>

   init(apiClient: APIClient, storage: AlertListStorage) {
      entityTransformer = DomainTransformer.alertList()
      let routerTransformer = RouterTransformer.alertList()
      let jsonTransformer = JsonTransformer.alertList()
      let network = NetworkDataSource(apiClient: apiClient,
                                      keyTransformer: routerTransformer,
                                      valueTransformer: jsonTransformer)

      cache = storage.compose(network)
   }
}

extension AlertRepository {
   func get(_ key: String) -> Observable<AlertList> {
      return cache.get(key)
         .flatMap(entityTransformer.transform)
   }
}
