//
//  PeekWatchlistUseCaseCoordinator.swift
//  Domain
//
//  Created by Hong on 27/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct PeekWatchlistUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias ReadAction = () -> Observable<Watchlist>

   let readAction: ReadAction

   public let watchList: Watchlist?

   public init(watchList: Watchlist? = nil,
               readAction: @escaping ReadAction) {
      self.readAction = readAction
      self.watchList = watchList
   }

   // MARK: - Requests

   func peekListRequest() -> Observable<Watchlist> {
      return readAction()
   }

   // MARK: - Executors

   func peekList() -> Observable<PeekWatchlistUseCaseCoordinator> {
      return peekListRequest().map(replacing)
   }

   // MARK: - Results

   public func readResult() -> Observable<Result<PeekWatchlistUseCaseCoordinator>> {
      return result(from: peekList()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(watchList: Watchlist?) -> PeekWatchlistUseCaseCoordinator {
      return .init(watchList: watchList,
                   readAction: readAction)
   }
}
