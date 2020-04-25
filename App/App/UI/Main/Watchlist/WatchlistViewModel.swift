//
//  WatchlistViewModel.swift
//  App
//
//  Created by Hong on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import FirebaseCrashlytics
import Domain
import RxCocoa
import RxDataSources
import RxSwift

final class WatchlistViewModel: TransformableViewModelType, Navigable {
   weak var navigator: WatchlistNavigatorType!

   init(navigator: WatchlistNavigatorType) {
      self.navigator = navigator
   }

   struct Input {
      let addWatchlistButtonObservable: Observable<Void>
      let watchlistDeleteObservable: Observable<IndexPath>
      let visibleCellRows: Driver<[Int]>
      let viewDisappeared: Driver<Void>
      let cellSelected: Observable<MutableBox<CurrencyPair>>
      let fromIndexToIndexObservable: Observable<(IndexPath, IndexPath)>
   }

   struct Output {
      let currencyPairs: Driver<[WatchlistListData]>
      let streamPrice: Driver<StreamPrice>
      let loadStateViewModel: LoadStateViewModel
      let addWatchlistDriver: Driver<Void>
      let updateWatchlistDriver: Driver<Void>
      let reloadTriggerDriver: Driver<Void>
      let historicalPriceAPI: (HistoricalPriceListRequest) -> Driver<HistoricalPriceList>
      let unsubscribeSocket: Driver<Void>
      let cellSelected: Driver<Void>
      let isLoading: Driver<Bool>
      let loadingIndicatorState: Driver<LoadingIndicatorState>
      let reloadTableViewOnErrorSignal: Signal<Void>
   }

   fileprivate typealias VisibleRowAndCurrencyPair = (rows: [Int], currencyPairs: [CurrencyPair])

   // swiftlint:disable function_body_length
   func transform(input: Input) -> WatchlistViewModel.Output {
      func getWatchlist() -> Driver<Result<GetWatchlistUseCaseCoordinator>> {
         return navigator.state.preferences.serviceProvider
            .repository.watchlist.watchlist()
            .readResult()
            .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
      }

      let loadStateViewModel = LoadStateViewModel()

      let reloadTrigger = navigator.defaultTriggers.reloadTrigger

      let watchlist = BehaviorRelay<Watchlist?>(value: nil)

      let validCurrencyPairs = navigator.state.preferences.serviceProvider
         .repository.prices.currencyPairList()
         .getResult()
         .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
         .filter { $0.hasContent }
         .map { $0.contentValue?.priceList?.flattened }
         .filterNil()

      let watchlistSourceObservable = getWatchlist()

      let watchlistResult = Driver.zip(validCurrencyPairs, getWatchlist()
         .filter { $0.hasContent }
         .map { $0.contentValue?.watchList }
         .filterNil())
         .map { pairsInConfig, watchlist in
            let sanitisedPairs = watchlist.currencyPairs.filter { pairsInConfig.contains($0) }
            return Watchlist(id: watchlist.id, currencyPairs: sanitisedPairs,
                             modifyDate: watchlist.modifyDate)
         }
         .do(onNext: { wl in
            watchlist.accept(wl)
         })

      let reloadTriggerDriver = reloadTrigger.flatMapLatest { _ in
         watchlistResult.void()
      }

      let currencyPairs = watchlist.asDriver()
         .filterNil()
         .map { $0.currencyPairs }

      let visibleCurrencyPair = input.visibleCellRows
         .withLatestFrom(currencyPairs) { VisibleRowAndCurrencyPair(rows: $0, currencyPairs: $1) }
         .flatMapLatest { rowAndCurrency -> Driver<[CurrencyPair]> in
            let firstIndex = rowAndCurrency.rows.first ?? 0
            var lastIndex = 0
            if let last = rowAndCurrency.rows.last {
               lastIndex = last + 1
            }

            let finalCurrencyArray = Array(rowAndCurrency.currencyPairs[firstIndex..<lastIndex])

            return Driver.just(finalCurrencyArray)
         }

      let streamPrice = visibleCurrencyPair.flatMapLatest { pair -> Driver<StreamPrice> in
         let getPriceListRequest = GetPriceListRequest(currencyPairs: pair)
         return self.navigator.state.preferences
            .serviceProvider.repository.prices
            .streamPrice(request: getPriceListRequest)
            .getResult()
            .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
            .filter { $0.hasContent }
            .map { $0.contentValue?.streamPrice }
            .filterNil()
      }

      let dataLoadState = watchlistSourceObservable.map { $0.isLoading ? LoadState.loading : LoadState.ready }
      let currencyPairsLoadState = currencyPairs.map { $0.isEmpty ? LoadState.emptyWatchlist : LoadState.ready }
      let loadState = Driver.merge([dataLoadState, currencyPairsLoadState])
      _ = loadStateViewModel.transform(input: .init(navigator: navigator,
                                                    strategy: .watchlist,
                                                    loadState: loadState))

      let addWatchlistDriver = input.addWatchlistButtonObservable.do(onNext: {
         self.navigator.showWatchlistAddCoin()
      }).asDriver()

      let updateWatchlistApi = input.fromIndexToIndexObservable
         .withLatestFrom(watchlist.asObservable().filterNil()) { ($0, $1) }
         .flatMap { [weak self] fromIndexToIndex, dbWatchlist
            -> Observable<Result<SetWatchlistUseCaseCoordinator>> in
            guard let `self` = self else {
               return .just(.failure(.error(UseCaseError.executionFailed)))
            }

            let (from, to) = fromIndexToIndex
            var currencyPairs = dbWatchlist.currencyPairs
            let currencyPair = currencyPairs.remove(at: from.row)
            currencyPairs.insert(currencyPair, at: to.row)
            let request = SetWatchlistRequest(currencyPairs: currencyPairs)

            return self.navigator.state.preferences
               .serviceProvider.repository
               .watchlist
               .writeWatchlist(request: request)
               .getResult()
         }
         .asDriver(onErrorJustReturn:
            .failure(.error(UseCaseError.executionFailed)))

      let prepareDeleteApi = input.watchlistDeleteObservable
         .withLatestFrom(watchlist.asObservable().filterNil()) { ($0, $1) }
         .flatMapLatest { [weak self] indexPath, dbWatchlist
            -> Observable<Result<SetWatchlistUseCaseCoordinator>> in
            guard let `self` = self else {
               return .just(.failure(.error(UseCaseError.executionFailed)))
            }

            var currencyPairs = dbWatchlist.currencyPairs
            currencyPairs.remove(at: indexPath.row)
            let request = SetWatchlistRequest(currencyPairs: currencyPairs)

            return self.navigator.state.preferences
               .serviceProvider.repository
               .watchlist
               .writeWatchlist(request: request)
               .getResult()
         }
         .asDriver(onErrorJustReturn:
            .failure(.error(UseCaseError.executionFailed)))

      let updateWatchlistErrorPublishRelay = PublishRelay<Void>()

      let updateWatchlistDriver = Driver.merge(prepareDeleteApi, updateWatchlistApi)
         .do(onNext: { result in
            switch result {
            case .failure:
               updateWatchlistErrorPublishRelay.accept(())
            default:
               break
            }
         })
         .filter { $0.hasContent }
         .map { $0.contentValue?.watchList }
         .filterNil()
         .do(onNext: { wl in
            watchlist.accept(wl)
         })
         .void()

      let displayCurrencyPair = currencyPairs
         .asDriver(onErrorJustReturn: [])
         .map {
            [WatchlistListData(header: "", items: $0.map { MutableBox($0) })]
         }

      let historicalPriceAPI: (HistoricalPriceListRequest) -> Driver<HistoricalPriceList> = { request in
         self.navigator.state.preferences.serviceProvider.repository.prices
            .historicalPrice(request: request)
            .getResult()
            .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
            .filter { $0.hasContent }
            .map { $0.contentValue?.historicalPriceList }
            .filterNil()
      }

      let unsubscribeSocket = input.viewDisappeared
         .flatMapLatest {
            self.navigator.state.preferences
               .serviceProvider.repository
               .stream
               .unsubscribe()
               .unsubscribeResult()
               .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
               .filter { $0.hasContent }
         }.void()

      let defaultCurrencyPair = CurrencyPair(baseCurrency: Currency(id: "BTC", name: "Bitcoin", symbol: "BTC"),
                                             quoteCurrency: Currency(id: "USD", name: "US Dollar", symbol: "USD"),
                                             exchange: Exchange(id: "Gemini", name: "Gemini"),
                                             price: 0.0)
      let cellSelected = input.cellSelected
         .asDriver(onErrorJustReturn: .init(defaultCurrencyPair))
         .map { $0.value }
         .do(onNext: { [weak self] currencyPair in
            var metadata = currencyPair.analyticsMetadata
            metadata.updateValue("Tapping on row", forKey: "Navigation Method")
            AnalyticsProvider.log(event: "Show Currency Pair Detail", metadata: metadata)

            self?.navigator.showWatchlistDetail(currencyPair)
         })
         .void()

      let isLoading = Driver.merge(prepareDeleteApi, updateWatchlistApi)
         .map { $0.isLoading }

      let loadingIndicatorState: Driver<LoadingIndicatorState> =
         isLoading.map { $0 ? .loading : .dismiss(completion: {}) }

      return Output(currencyPairs: displayCurrencyPair,
                    streamPrice: streamPrice,
                    loadStateViewModel: loadStateViewModel,
                    addWatchlistDriver: addWatchlistDriver,
                    updateWatchlistDriver: updateWatchlistDriver,
                    reloadTriggerDriver: reloadTriggerDriver,
                    historicalPriceAPI: historicalPriceAPI,
                    unsubscribeSocket: unsubscribeSocket,
                    cellSelected: cellSelected,
                    isLoading: isLoading,
                    loadingIndicatorState: loadingIndicatorState,
                    reloadTableViewOnErrorSignal: updateWatchlistErrorPublishRelay.asSignal())
   }
}
