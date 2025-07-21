//
//  PriceListUseCaseCoordinator.swift
//  Domain
//
//  Created by Ryne Cheow on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct CurrencyPairListUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias GetAction = (String) -> Observable<CurrencyPairList>

   public let priceList: CurrencyPairList?

   let key: String

   let getAction: GetAction

   public init(priceList: CurrencyPairList? = nil, getAction: @escaping GetAction) {
      self.priceList = priceList
      key = "BitpalCurrencies"
      self.getAction = getAction
   }

   // MARK: - Requests

   func getRequest() -> Observable<CurrencyPairList> {
      return getAction(key)
   }

   // MARK: - Executors

   func get() -> Observable<CurrencyPairListUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Results

   public func getResult() -> Observable<Result<CurrencyPairListUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(priceList newPriceList: CurrencyPairList) -> CurrencyPairListUseCaseCoordinator {
      return .init(priceList: newPriceList, getAction: getAction)
   }
}
