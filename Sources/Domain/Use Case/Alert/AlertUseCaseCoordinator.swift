//
//  AlertUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 17/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct AlertUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias GetAction = (String) -> Observable<AlertList>

   public let alertList: AlertList?

   let request: String

   let getAction: GetAction

   public init(alertList: AlertList? = nil,
               request: String,
               getAction: @escaping GetAction) {
      self.alertList = alertList
      self.request = request
      self.getAction = getAction
   }

   // MARK: - Requests

   func getRequest() -> Observable<AlertList> {
      return getAction(request)
   }

   // MARK: - Executors

   func get() -> Observable<AlertUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Responses

   public func getResult() -> Observable<Result<AlertUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(alertList: AlertList) -> AlertUseCaseCoordinator {
      return .init(alertList: alertList, request: request, getAction: getAction)
   }
}
