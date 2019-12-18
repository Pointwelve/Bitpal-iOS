//
//  WidgetCurrencyDetailRepository.swift
//  Data
//
//  Created by Li Hao Lai on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

class WidgetCurrencyDetailRepository: CurrencyDetailRepositoryType {
   typealias Key = GetCurrencyDetailRequest
   typealias Value = CurrencyDetail

   fileprivate let entityTransformer: BidirectionalValueTransformerBox<CurrencyDetailData, CurrencyDetail>
   fileprivate let network: NetworkDataSource<GetCurrencyDetailRequest, CurrencyDetailData, APIClient>

   init(apiClient: APIClient) {
      entityTransformer = DomainTransformer.currencyDetail()
      let routerTransformer = RouterTransformer.currencyDetail()
      let jsonTransformer = JsonTransformer.currencyDetail()
      network = NetworkDataSource(apiClient: apiClient,
                                  keyTransformer: routerTransformer,
                                  valueTransformer: jsonTransformer)
   }
}

extension WidgetCurrencyDetailRepository {
   func get(_ key: GetCurrencyDetailRequest) -> Observable<CurrencyDetail> {
      return network.get(key)
         .flatMap(entityTransformer.transform)
   }
}
