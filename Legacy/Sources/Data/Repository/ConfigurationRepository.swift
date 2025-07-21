//
//  ConfigurationRepository.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias ConfigurationRepositoryType = Readable

class ConfigurationRepository: ConfigurationRepositoryType {
   typealias Key = Void
   typealias Value = Configuration

   fileprivate let defaultKey = "default"
   fileprivate let cache: BasicCache<String, ConfigurationData>
   fileprivate let entityTransformer: BidirectionalValueTransformerBox<ConfigurationData, Configuration>

   init(storage: ConfigurationStorage) {
      cache = CacheFactory.memoryCache(combinedWith: storage)
      entityTransformer = DomainTransformer.configuration()
   }
}

extension ConfigurationRepository {
   func read() -> Observable<Value> {
      return cache
         .get(defaultKey)
         .flatMap(entityTransformer.transform)
   }
}
