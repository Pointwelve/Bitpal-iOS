//
//  WatchlistSelectExchangeViewModel.swift
//  App
//
//  Created by Li Hao on 19/1/18.
//  Copyright © 2018 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class WatchlistSelectExchangeViewModel: TransformableViewModelType, Navigable {
   struct Input {
      let tableViewItemSelected: Driver<Exchange>
   }

   struct Output {
      let exchanges: Driver<[Exchange]>
      let tableViewItemSelected: Driver<Void>
      let loadStateViewModel: LoadStateViewModel
      let isLoading: Driver<Bool>
      let loadingIndicatorState: Driver<LoadingIndicatorState>
   }

   weak var navigator: WatchlistSelectExchangeNavigator!

   init(navigator: WatchlistSelectExchangeNavigator) {
      self.navigator = navigator
   }

   func transform(input: Input) -> Output {
      func setWatchlist(_ request: SetWatchlistRequest)
         -> Observable<Result<SetWatchlistUseCaseCoordinator>> {
         return navigator.state.preferences
            .serviceProvider.repository.watchlist
            .writeWatchlist(request: request)
            .getResult()
      }

      let watchlistObservable = navigator.state.preferences
         .serviceProvider.repository.watchlist
         .watchlist()
         .readResult()
         .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
         .filter { $0.hasContent }
         .map { $0.contentValue?.watchList }
         .filterNil()

      let prepareAddCoinApi =
         input.tableViewItemSelected
         .withLatestFrom(watchlistObservable) { ($0, $1) }
         .flatMapLatest { [weak self] selectedExchange, watchlist
            -> Driver<(Result<SetWatchlistUseCaseCoordinator>, CurrencyPair)?> in
            guard let currencyPairGroup = self?.navigator.currencyPairGroup else {
               return .just(nil)
            }

            let newCurrencyPair = CurrencyPair(baseCurrency: currencyPairGroup.baseCurrency,
                                               quoteCurrency: currencyPairGroup.quoteCurrency,
                                               exchange: selectedExchange,
                                               price: 0.0)
            var newCurrencyPairs = watchlist.currencyPairs

            for (index, currencyPair) in newCurrencyPairs.enumerated()
               where currencyPair == newCurrencyPair {
               newCurrencyPairs.remove(at: index)
            }

            newCurrencyPairs.append(newCurrencyPair)

            let request = SetWatchlistRequest(currencyPairs: newCurrencyPairs)

            return setWatchlist(request)
               .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
               .map { ($0, newCurrencyPair) }
         }
         .filterNil()

      let tableViewItemSelected = prepareAddCoinApi
         .filter { $0.0.hasContent }
         .map { ($0.0.contentValue?.watchList, $0.1) }
         .do(onNext: { _, currencyPair in
            AnalyticsProvider.log(event: "Added Currency Pair to Watchlist",
                                  metadata: currencyPair.analyticsMetadata)
         })
         .void()
         .asDriver()

      let isLoading = prepareAddCoinApi
         .map { $0.0.isLoading }
         .asDriver(onErrorJustReturn: false)

      let finishAddCoin = { [weak self] in
         guard let `self` = self else {
            return
         }

         self.navigator.dimissSelectExchange()
      }

      let loadingIndicatorState: Driver<LoadingIndicatorState> =
         isLoading.map { $0 ? .loading : .dismiss(completion: finishAddCoin) }

      let exchanges = navigator.currencyPairGroup.exchanges

      let loadStateViewModel = LoadStateViewModel()

      let loadState = Driver.just(LoadState.ready)
      _ = loadStateViewModel.transform(input:
         .init(navigator: navigator, strategy: .addCoinSearch, loadState: loadState))

      return .init(exchanges: .just(exchanges),
                   tableViewItemSelected: tableViewItemSelected,
                   loadStateViewModel: loadStateViewModel,
                   isLoading: isLoading,
                   loadingIndicatorState: loadingIndicatorState)
   }
}
