//
//  DeviceFingerprintUseCaseCoordinator.swift
//  Domain
//
//  Created by James Lai on 19/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct DeviceFingerprintUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<String>

   public let data: String?

   let readAction: ReadAction

   public init(data: String? = nil, readAction: @escaping ReadAction) {
      self.data = data
      self.readAction = readAction
   }

   func readRequest() -> Observable<String> {
      return readAction()
   }

   func read() -> Observable<DeviceFingerprintUseCaseCoordinator> {
      return readRequest().map(replacing)
   }

   public func readResult() -> Observable<Result<DeviceFingerprintUseCaseCoordinator>> {
      return result(from: read()).startWith(.content(.with(self, .loading)))
   }

   func replacing(data newData: String) -> DeviceFingerprintUseCaseCoordinator {
      return .init(data: newData, readAction: readAction)
   }
}
