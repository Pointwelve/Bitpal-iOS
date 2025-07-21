//
//  StreamUseCaseCoordinator.swift
//  Domain
//
//  Created by Kok Hong Choo on 9/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct StreamUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<Void>

   let readAction: ReadAction

   public init(readAction: @escaping ReadAction) {
      self.readAction = readAction
   }

   // MARK: - Requests

   func unsubscribeRequest() -> Observable<Void> {
      return readAction()
   }

   // MARK: - Executors

   func unsubscribe() -> Observable<StreamUseCaseCoordinator> {
      return unsubscribeRequest().map(replacing)
   }

   // MARK: - Results

   public func unsubscribeResult() -> Observable<Result<StreamUseCaseCoordinator>> {
      return result(from: unsubscribe())
   }

   // MARK: - Replacements

   func replacing() -> StreamUseCaseCoordinator {
      return .init(readAction: readAction)
   }
}
