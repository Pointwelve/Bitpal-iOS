//
//  UserIdentifierUseCaseCoordinator.swift
//  Domain
//
//  Created by Ryne Cheow on 24/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//
import Foundation
import RxSwift

public struct UserIdentifierUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<String>

   public let identifier: String?

   let readAction: ReadAction

   public init(identifier: String? = nil, getAction: @escaping ReadAction) {
      self.identifier = identifier
      readAction = getAction
   }

   // MARK: - Requests

   func readRequest() -> Observable<String> {
      return readAction()
   }

   // MARK: - Executors

   func read() -> Observable<UserIdentifierUseCaseCoordinator> {
      return readRequest().map(replacing)
   }

   // MARK: - Results

   public func getResult() -> Observable<Result<UserIdentifierUseCaseCoordinator>> {
      return result(from: read()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(identifier newIdentifier: String) -> UserIdentifierUseCaseCoordinator {
      return .init(identifier: newIdentifier, getAction: readAction)
   }
}
