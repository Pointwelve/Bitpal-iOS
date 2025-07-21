//
//  CurrencyDetailUseCaseCoordinator.swift
//  Domain
//
//  Created by Kok Hong Choo on 16/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct CurrencyDetailUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias GetAction = (GetCurrencyDetailRequest) -> Observable<CurrencyDetail>

   public let currencyDetail: CurrencyDetail?

   let request: GetCurrencyDetailRequest

   let getAction: GetAction

   public init(currencyDetail: CurrencyDetail? = nil,
               request: GetCurrencyDetailRequest, getAction: @escaping GetAction) {
      self.currencyDetail = currencyDetail
      self.request = request
      self.getAction = getAction
   }

   // MARK: - Requests

   func getRequest() -> Observable<CurrencyDetail> {
      return getAction(request)
   }

   // MARK: - Executors

   func get() -> Observable<CurrencyDetailUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Results

   public func getResult() -> Observable<Result<CurrencyDetailUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(currencyDetail newCurrencyDetail: CurrencyDetail) -> CurrencyDetailUseCaseCoordinator {
      return .init(currencyDetail: newCurrencyDetail, request: request, getAction: getAction)
   }
}
