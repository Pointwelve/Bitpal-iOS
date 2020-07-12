//
//  PushNotificationUseCaseCoordinator.swift
//  Domain
//
//  Created by Ryne Cheow on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct PushNotificationUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias GetAction = (String) -> Observable<Void>

   let request: String

   let getAction: GetAction

   public init(request: String,
               getAction: @escaping GetAction) {
      self.request = request
      self.getAction = getAction
   }

   // MARK: - Requests

   func getRequest() -> Observable<Void> {
      return getAction(request)
   }

   // MARK: - Executors

   func get() -> Observable<PushNotificationUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Responses

   public func getResult() -> Observable<Result<PushNotificationUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing() -> PushNotificationUseCaseCoordinator {
      return .init(request: request, getAction: getAction)
   }
}
