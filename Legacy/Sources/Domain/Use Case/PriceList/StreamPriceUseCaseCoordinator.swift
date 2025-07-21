//
//  StreamPriceUseCaseCoordinator.swift
//  Domain
//
//  Created by Ryne Cheow on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct StreamPriceUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias StreamAction = (GetPriceListRequest) -> Observable<StreamPrice>

   public let streamPrice: StreamPrice?

   let request: GetPriceListRequest

   let streamAction: StreamAction

   public init(streamPrice: StreamPrice? = nil, request: GetPriceListRequest, streamAction: @escaping StreamAction) {
      self.streamPrice = streamPrice
      self.request = request
      self.streamAction = streamAction
   }

   // MARK: - Requests

   func getRequest() -> Observable<StreamPrice> {
      return streamAction(request)
   }

   // MARK: - Executors

   func get() -> Observable<StreamPriceUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Results

   public func getResult() -> Observable<Result<StreamPriceUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(streamPrice newStreamPrice: StreamPrice) -> StreamPriceUseCaseCoordinator {
      return .init(streamPrice: newStreamPrice, request: request, streamAction: streamAction)
   }
}
