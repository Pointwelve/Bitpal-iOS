//
//  PushNotificationRegistrationRepository.swift
//  Data
//
//  Created by Ryne Cheow on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias PushNotificationRegistrationRepositoryType = Gettable

class PushNotificationRegistrationRepository: PushNotificationRegistrationRepositoryType {
   typealias Key = String
   typealias Value = Void

   fileprivate let cache: BasicCache<String, StandardResponseData>

   init(apiClient: APIClient) {
      cache = NetworkDataSource(apiClient: apiClient,
                                keyTransformer: RouterTransformer.registerPush(),
                                valueTransformer: JsonTransformer.standardResponse()).asBasicCache()
   }
}

extension PushNotificationRegistrationRepository {
   func get(_ key: String) -> Observable<Void> {
      return cache.get(key).map { _ in () }
   }
}
