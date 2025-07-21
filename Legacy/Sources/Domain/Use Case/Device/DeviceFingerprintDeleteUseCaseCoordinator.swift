//
//  DeviceFingerprintDeleteUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct DeviceFingerprintDeleteUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias DeleteAction = () -> Observable<String>

   let deleteAction: DeleteAction

   public init(deleteAction: @escaping DeleteAction) {
      self.deleteAction = deleteAction
   }

   func deleteRequest() -> Observable<String> {
      return deleteAction()
   }

   func delete() -> Observable<DeviceFingerprintDeleteUseCaseCoordinator> {
      return deleteRequest().map(replacing)
   }

   public func deleteResult() -> Observable<Result<DeviceFingerprintDeleteUseCaseCoordinator>> {
      return result(from: delete()).startWith(.content(.with(self, .loading)))
   }

   func replacing(string: String) -> DeviceFingerprintDeleteUseCaseCoordinator {
      return .init(deleteAction: deleteAction)
   }
}
