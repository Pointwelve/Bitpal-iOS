//
//  FirebaseWatchlistUseCaseCoordinator.swift
//  Domain
//
//  Created by Kok Hong Choo on 24/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public struct SetWatchlistUseCaseCoordinator: UseCaseCoordinatorType {
   public typealias GetAction = (SetWatchlistRequest) -> Observable<Watchlist>

   let request: SetWatchlistRequest

   let getAction: GetAction

   public let watchList: Watchlist?

   public init(watchList: Watchlist? = nil,
               request: SetWatchlistRequest,
               getAction: @escaping GetAction) {
      self.request = request
      self.getAction = getAction
      self.watchList = watchList
   }

   // MARK: - Requests

   func getRequest() -> Observable<Watchlist> {
      return getAction(request)
   }

   // MARK: - Executors

   func get() -> Observable<SetWatchlistUseCaseCoordinator> {
      return getRequest().map(replacing)
   }

   // MARK: - Results

   public func getResult() -> Observable<Result<SetWatchlistUseCaseCoordinator>> {
      return result(from: get()).startWith(.content(.with(self, .loading)))
   }

   // MARK: - Replacements

   func replacing(watchList: Watchlist?) -> SetWatchlistUseCaseCoordinator {
      return .init(watchList: watchList,
                   request: request,
                   getAction: getAction)
   }
}
