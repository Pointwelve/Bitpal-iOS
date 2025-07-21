//
//  CreateAlertUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 19/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct CreateAlertUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias UpdateAction = (CreateAlertRequest) -> Observable<String>

   public let message: String?

   let request: CreateAlertRequest

   let updateAction: UpdateAction

   public init(message: String? = nil,
               request: CreateAlertRequest,
               updateAction: @escaping UpdateAction) {
      self.message = message
      self.request = request
      self.updateAction = updateAction
   }

   // MARK: - Requests

   func updateRequest() -> Observable<String> {
      return updateAction(request)
   }

   // MARK: - Executors

   func update() -> Observable<CreateAlertUseCaseCoordinator> {
      return updateRequest().map(replacing)
   }

   // MARK: - Responses

   public func updateResult() -> Observable<Result<CreateAlertUseCaseCoordinator>> {
      return result(from: update()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(message: String) -> CreateAlertUseCaseCoordinator {
      return .init(message: message, request: request, updateAction: updateAction)
   }
}
