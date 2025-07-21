//
//  DeleteAlertUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 25/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct DeleteAlertUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias DeleteAction = (String) -> Observable<Void>

   let request: String

   let deleteAction: DeleteAction

   public init(request: String,
               deleteAction: @escaping DeleteAction) {
      self.request = request
      self.deleteAction = deleteAction
   }

   // MARK: - Requests

   func deleteRequest() -> Observable<Void> {
      return deleteAction(request)
   }

   // MARK: - Executors

   func delete() -> Observable<DeleteAlertUseCaseCoordinator> {
      return deleteRequest().map(replacing)
   }

   // MARK: - Responses

   public func deleteResult() -> Observable<Result<DeleteAlertUseCaseCoordinator>> {
      return result(from: delete()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing() -> DeleteAlertUseCaseCoordinator {
      return .init(request: request, deleteAction: deleteAction)
   }
}
