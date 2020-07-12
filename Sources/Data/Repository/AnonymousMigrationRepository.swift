//
//  AnonymousMigrationRepository.swift
//  Data
//
//  Created by James Lai on 15/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias AnonymousMigrationRepositoryType = Updateable

class AnonymousMigrationRepository: AnonymousMigrationRepositoryType {
   typealias Key = AnonymousMigrationRequest
   typealias Value = AnonymousMigrationResponse
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<AnonymousMigrationResponseData, AnonymousMigrationResponse>
   fileprivate let network: NetworkDataSource<AnonymousMigrationRequest, AnonymousMigrationResponseData, APIClient>

   init(apiClient: APIClient) {
      entityTransformer = DomainTransformer.anonymousMigrationResponse()
      let routerTransformer = RouterTransformer.anonymousMigration()
      let jsonTransformer = JsonTransformer.anonymousMigration()
      network = NetworkDataSource(apiClient: apiClient,
                                  keyTransformer: routerTransformer,
                                  valueTransformer: jsonTransformer)
   }
}

extension AnonymousMigrationRepository {
   func update(_ key: AnonymousMigrationRequest) -> Observable<AnonymousMigrationResponse> {
      return network.get(key)
         .flatMap(entityTransformer.transform)
   }
}
