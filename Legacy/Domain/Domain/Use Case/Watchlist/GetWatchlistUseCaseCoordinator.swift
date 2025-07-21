//
//  GetWatchlistUseCaseCoordinator.swift
//  Domain
//
//  Created by Kok Hong Choo on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct GetWatchlistUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<Watchlist>

   let readAction: ReadAction

   public let watchList: Watchlist?

   public init(watchList: Watchlist? = nil,
               readAction: @escaping ReadAction) {
      self.watchList = watchList
      self.readAction = readAction
   }

   // MARK: - Requests

   func readRequest() -> Observable<Watchlist> {
      return readAction()
   }

   // MARK: - Executors

   func read() -> Observable<GetWatchlistUseCaseCoordinator> {
      return readRequest().map(replacing)
   }

   // MARK: - Results

   public func readResult() -> Observable<Result<GetWatchlistUseCaseCoordinator>> {
      return result(from: read()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(watchList: Watchlist?) -> GetWatchlistUseCaseCoordinator {
      return .init(watchList: watchList,
                   readAction: readAction)
   }
}
