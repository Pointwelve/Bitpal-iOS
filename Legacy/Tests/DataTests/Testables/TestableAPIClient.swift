//
//  TestableAPIClient.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import Foundation
import RxSwift

class TestableAPIClient: APIClient {
   override func executeRequest(for router: APIClient.Key) -> Observable<APIClient.Value> {
      return Observable.empty()
   }
}
