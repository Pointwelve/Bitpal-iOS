//
//  AuthenticationUseCaseCoordinator.swift
//  Domain
//
//  Created by Ryne Cheow on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct AuthenticationUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<UserType>

   let readAction: ReadAction

   public var user: UserType?

   public init(user: UserType? = nil, readAction: @escaping ReadAction) {
      self.user = user
      self.readAction = readAction
   }

   // MARK: - Requests

   func readRequest() -> Observable<UserType> {
      return readAction()
   }

   // MARK: - Executors

   func read() -> Observable<AuthenticationUseCaseCoordinator> {
      return readRequest().map(replacing)
   }

   // MARK: - Results

   public func readResult() -> Observable<Result<AuthenticationUseCaseCoordinator>> {
      return result(from: read()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(user newUser: UserType) -> AuthenticationUseCaseCoordinator {
      return .init(user: newUser, readAction: readAction)
   }
}
