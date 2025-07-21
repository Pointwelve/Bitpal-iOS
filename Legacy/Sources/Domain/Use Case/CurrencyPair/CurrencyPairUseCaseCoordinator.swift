//
//  CurrencyPairUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao on 29/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct GetCurrencyPairUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias GetAction = (String) -> Observable<CurrencyPair>

   let request: String

   let getAction: GetAction

   public let currencyPair: CurrencyPair?

   public init(currencyPair: CurrencyPair? = nil,
               request: String,
               getAction: @escaping GetAction) {
      self.currencyPair = currencyPair
      self.request = request
      self.getAction = getAction
   }

   // MARK: - Requests

   func getRequest() -> Observable<CurrencyPair> {
      return getAction(request)
   }

   // MARK: - Executors

   func get() -> Observable<GetCurrencyPairUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Results

   public func getResult() -> Observable<Result<GetCurrencyPairUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(currencyPair: CurrencyPair?) -> GetCurrencyPairUseCaseCoordinator {
      return .init(currencyPair: currencyPair,
                   request: request,
                   getAction: getAction)
   }
}
