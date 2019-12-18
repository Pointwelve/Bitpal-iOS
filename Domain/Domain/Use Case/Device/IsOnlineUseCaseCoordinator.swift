//
//  IsOnlineUseCaseCoordinator.swift
//  Domain
//
//  Created by Ryne Cheow on 5/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct IsOnlineUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias GetAction = () -> Observable<Bool>

   public let isOnline: Bool

   let getAction: GetAction

   public init(isOnline: Bool = false, getAction: @escaping GetAction) {
      self.isOnline = isOnline
      self.getAction = getAction
   }

   // MARK: - Requests

   func getRequest() -> Observable<Bool> {
      return getAction()
   }

   // MARK: - Executors

   func get() -> Observable<IsOnlineUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Result

   public func getResult() -> Observable<Result<IsOnlineUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(isOnline newIsOnline: Bool) -> IsOnlineUseCaseCoordinator {
      return .init(isOnline: newIsOnline, getAction: getAction)
   }
}
