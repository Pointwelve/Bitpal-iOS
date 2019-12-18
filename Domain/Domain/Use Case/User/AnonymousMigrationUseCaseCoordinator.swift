//
//  AnonymousMigrationUseCaseCoordinator.swift
//  Domain
//
//  Created by James Lai on 15/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct AnonymousMigrationUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias UpdateAction = (AnonymousMigrationRequest) -> Observable<AnonymousMigrationResponse>
   public typealias Request = AnonymousMigrationRequest

   public let response: AnonymousMigrationResponse?

   let request: Request

   let updateAction: UpdateAction

   public init(response: AnonymousMigrationResponse? = nil,
               request: AnonymousMigrationRequest,
               updateAction: @escaping UpdateAction) {
      self.response = response
      self.request = request
      self.updateAction = updateAction
   }

   // MARK: - Requests

   func updateRequest() -> Observable<AnonymousMigrationResponse> {
      return updateAction(request)
   }

   // MARK: - Executors

   func update() -> Observable<AnonymousMigrationUseCaseCoordinator> {
      return updateRequest().map(replacing)
   }

   // MARK: - Results

   public func updateResult() -> Observable<Result<AnonymousMigrationUseCaseCoordinator>> {
      return result(from: update()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(responsee newResponse: AnonymousMigrationResponse) -> AnonymousMigrationUseCaseCoordinator {
      return .init(response: newResponse,
                   request: request,
                   updateAction: updateAction)
   }
}
