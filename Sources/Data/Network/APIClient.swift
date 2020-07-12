//
//  APIClient.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxSwift

protocol APIClientType {
   associatedtype Key
   associatedtype Value

   func executeRequest(for router: Key) -> Observable<Value>
}

class APIClient: APIClientType {
   typealias Key = Router
   typealias Value = Any

   init() {}

   func executeRequest(for router: Key) -> Observable<Value> {
      fatalError("Must override")
   }
}
