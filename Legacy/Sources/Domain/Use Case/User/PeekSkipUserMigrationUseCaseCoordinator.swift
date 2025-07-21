//
//  PeekSkipUserMigrationUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct PeekSkipUserMigrationUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias PeekAction = () -> Observable<Bool>

   public let response: Bool?

   let peekAction: PeekAction

   public init(response: Bool? = nil,
               peekAction: @escaping PeekAction) {
      self.response = response
      self.peekAction = peekAction
   }

   // MARK: - Requests

   func peekRequest() -> Observable<Bool> {
      return peekAction()
   }

   // MARK: - Executors

   func peek() -> Observable<PeekSkipUserMigrationUseCaseCoordinator> {
      return peekRequest().map(replacing)
   }

   // MARK: - Results

   public func peekResult() -> Observable<Result<PeekSkipUserMigrationUseCaseCoordinator>> {
      return result(from: peek()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(value newValue: Bool?) -> PeekSkipUserMigrationUseCaseCoordinator {
      return .init(response: newValue,
                   peekAction: peekAction)
   }
}
