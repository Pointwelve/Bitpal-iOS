//
//  UpdateAlertUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 26/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct UpdateAlertUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias UpdateAction = (Alert) -> Observable<Void>

   let request: Alert

   let updateAction: UpdateAction

   public init(request: Alert,
               updateAction: @escaping UpdateAction) {
      self.request = request
      self.updateAction = updateAction
   }

   // MARK: - Requests

   func updateRequest() -> Observable<Void> {
      return updateAction(request)
   }

   // MARK: - Executors

   func update() -> Observable<UpdateAlertUseCaseCoordinator> {
      return updateRequest().map(replacing)
   }

   // MARK: - Responses

   public func updateResult() -> Observable<Result<UpdateAlertUseCaseCoordinator>> {
      return result(from: update()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing() -> UpdateAlertUseCaseCoordinator {
      return .init(request: request, updateAction: updateAction)
   }
}
