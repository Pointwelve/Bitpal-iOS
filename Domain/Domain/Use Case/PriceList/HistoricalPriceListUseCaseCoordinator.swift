//
//  HistoricalPriceListUseCaseCoordinator.swift
//  Domain
//
//  Created by Li Hao Lai on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct HistoricalPriceListUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias GetAction = (HistoricalPriceListRequest) -> Observable<HistoricalPriceList>

   public let historicalPriceList: HistoricalPriceList?

   let request: HistoricalPriceListRequest

   let getAction: GetAction

   public init(historicalPriceList: HistoricalPriceList? = nil,
               request: HistoricalPriceListRequest,
               getAction: @escaping GetAction) {
      self.historicalPriceList = historicalPriceList
      self.request = request
      self.getAction = getAction
   }

   // MARK: - Requests

   func getRequest() -> Observable<HistoricalPriceList> {
      return getAction(request)
   }

   // MARK: - Executors

   func get() -> Observable<HistoricalPriceListUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Results

   public func getResult() -> Observable<Result<HistoricalPriceListUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(priceList newPriceList: HistoricalPriceList) -> HistoricalPriceListUseCaseCoordinator {
      return .init(historicalPriceList: newPriceList, request: request, getAction: getAction)
   }
}
