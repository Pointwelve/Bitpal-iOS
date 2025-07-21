//
//  SetSkipUserMigrationUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct SetSkipUserMigrationUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias SetAction = (Bool) -> Observable<Bool>
   public typealias Request = Bool

   let request: Request

   public let response: Bool?

   let setAction: SetAction

   public init(response: Bool? = nil,
               request: Bool,
               setAction: @escaping SetAction) {
      self.response = response
      self.request = request
      self.setAction = setAction
   }

   // MARK: - Requests

   func setRequest() -> Observable<Bool> {
      return setAction(request)
   }

   // MARK: - Executors

   func set() -> Observable<SetSkipUserMigrationUseCaseCoordinator> {
      return setRequest().map(replacing)
   }

   // MARK: - Results

   public func setResult() -> Observable<Result<SetSkipUserMigrationUseCaseCoordinator>> {
      return result(from: set()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(value newValue: Bool?) -> SetSkipUserMigrationUseCaseCoordinator {
      return .init(response: newValue,
                   request: request,
                   setAction: setAction)
   }
}
