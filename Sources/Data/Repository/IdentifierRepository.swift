//
//  IdentifierRepository.swift
//  Data
//
//  Created by Ryne Cheow on 19/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

typealias IdentifierRepositoryType = Readable

class IdentifierRepository: IdentifierRepositoryType {
   typealias Key = Void
   typealias Value = String

   fileprivate let storage: IdentifierStorage

   init(storage: IdentifierStorage = IdentifieriCloudStorage()) {
      self.storage = storage
   }
}

extension IdentifierRepository {
   /// Unlike other network based use-cases this one actually continues to feed updates
   /// from the reachability class. Therefore there is no need to request it multiple
   /// times.
   func read() -> Observable<Value> {
      return storage.get("")
   }
}
