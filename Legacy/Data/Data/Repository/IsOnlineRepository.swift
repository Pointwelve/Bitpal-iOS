//
//  IsOnlineRepository.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias IsOnlineRepositoryType = Readable

class IsOnlineRepository: IsOnlineRepositoryType {
   typealias Key = Void
   typealias Value = Bool

   fileprivate let reachability: ReachabilityProvider

   init(reachability: ReachabilityProvider = RxReachabilityProvider()) {
      self.reachability = reachability
   }
}

extension IsOnlineRepository {
   /// Unlike other network based use-cases this one actually continues to feed updates
   /// from the reachability class. Therefore there is no need to request it multiple
   /// times.
   func read() -> Observable<Value> {
      return reachability.isOnline.asObservable()
   }
}
