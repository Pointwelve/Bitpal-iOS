//
//  TestableSocketClient.swift
//  Data
//
//  Created by Hong on 15/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import Foundation
import RxSwift

class TestableSocketClient: SocketClient {
   override func executeRequest(for router: Router) -> Observable<String> {
      return Observable.empty()
   }

   convenience init() {
      self.init(getSocketAction: { Observable.empty() },
                onAppEnteredBackground: Observable.empty(),
                onAppEnteredForeground: Observable.empty())
   }
}
