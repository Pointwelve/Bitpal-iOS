//
//  WatchlistAddCoinViewModel.swift
//  App
//
//  Created by Li Hao Lai on 25/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import FirebaseCrashlytics
import RxCocoa
import RxDataSources
import RxSwift

final class WatchlistAddCoinViewModel: TransformableViewModelType, Navigable {
   weak var navigator: WatchlistAddCoinNavigator!

   init(navigator: WatchlistAddCoinNavigator) {
      self.navigator = navigator
   }

   struct Input {
      let tableViewItemObservable: Observable<CurrencyPairGroup>
      let searchTextFieldObservable: Observable<String?>
      let tapClearButtonObservable: Observable<Void>
   }

   struct Output {
      let watchlistAddCoinListData: Driver<[WatchlistAddCoinListData]>
      let prepareSelectExchange: Driver<Void>
      let searchTextFieldDriver: Driver<String?>
      let tapClearButtonDriver: Driver<Void>
      let loadStateViewModel: LoadStateViewModel
   }

   func transform(input: Input) -> Output {
      let loadStateViewModel = LoadStateViewModel()

      let currencyPairGroupsDriver = navigator.state.preferences
         .serviceProvider.repository.prices
         .currencyPairList()
         .getResult()
         .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
         .filter { $0.hasContent }
         .map { $0.contentValue?.priceList?.currencyPairs }
         .filterNil()

      let data = input.searchTextFieldObservable.asDriver(onErrorJustReturn: nil)
         .debounce(.milliseconds(300))
         .startWith("")
         .withLatestFrom(currencyPairGroupsDriver) { ($1, $0) }
         .flatMapLatest { currencyPairGroups, searchText -> Driver<[WatchlistAddCoinListData]> in
            var currencyPairGroups = currencyPairGroups

            // filter with search query
            if let query = searchText?.lowercased(), query.isNotEmpty {
               if query.index(of: "/") != nil {
                  let rules = query.split(separator: "/").map { String($0) }

                  if rules.count >= 1 {
                     let base = rules[0]
                     let quote = rules.count > 1 ? rules[1] : ""

                     currencyPairGroups = currencyPairGroups.filter {
                        $0.baseCurrency.symbol.lowercased().index(of: base) != nil &&
                           (quote.isEmpty ||
                              $0.quoteCurrency.symbol.lowercased().index(of: quote) != nil)
                     }
                  }
               } else {
                  currencyPairGroups = currencyPairGroups.filter {
                     $0.baseCurrency.symbol.lowercased().index(of: query) != nil ||
                        $0.baseCurrency.name.lowercased().index(of: query) != nil ||
                        $0.quoteCurrency.symbol.lowercased().index(of: query) != nil ||
                        $0.quoteCurrency.name.lowercased().index(of: query) != nil
                  }
               }
            }

            // convert data to section data
            var data = [Currency: [CurrencyPairGroup]]()

            for currencyPairGroup in currencyPairGroups {
               if data[currencyPairGroup.baseCurrency] != nil {
                  data[currencyPairGroup.baseCurrency]?.append(currencyPairGroup)
               } else {
                  data[currencyPairGroup.baseCurrency] = [currencyPairGroup]
               }
            }

            let result = data.map { key, value -> WatchlistAddCoinListData in
               WatchlistAddCoinListData(header: key, items: value)
            }.sorted { $0.header.symbol.localizedCaseInsensitiveCompare($1.header.symbol) == .orderedAscending }

            return .just(result)
         }

      let prepareSelectExchange =
         input.tableViewItemObservable
            .do(onNext: { [weak self] currencyPairGroup in
               self?.navigator.showSelectExchange(with: currencyPairGroup)
            })
            .void()
            .asDriver()

      let tapClearButtonDriver = input.tapClearButtonObservable
         .asDriver()

      let loadState = data.map {
         $0.isEmpty ? LoadState.empty : LoadState.ready
      }
      _ = loadStateViewModel.transform(input:
         .init(navigator: navigator, strategy: .addCoinSearch, loadState: loadState))

      return .init(watchlistAddCoinListData: data,
                   prepareSelectExchange: prepareSelectExchange,
                   searchTextFieldDriver: input.searchTextFieldObservable.asDriver(onErrorJustReturn: nil),
                   tapClearButtonDriver: tapClearButtonDriver,
                   loadStateViewModel: loadStateViewModel)
   }
}
