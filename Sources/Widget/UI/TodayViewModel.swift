//
//  TodayViewModel.swift
//  Widget
//
//  Created by Li Hao Lai on 6/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class TodayViewModel {
   struct Input {
      let loadStateViewTap: Driver<Void>
   }

   struct Output {
      let watclistRequestDriver: Driver<Void>
      let getCurrencyDetailsAction: (GetCurrencyDetailRequest) -> CurrencyDetailUseCaseCoordinator
      let watchlist: Driver<[CurrencyPair]>
      let loadState: Driver<LoadState>
      let loadStateViewDidTap: Driver<Void>
   }

   let preference: WidgetPreference

   init(preference: WidgetPreference) {
      self.preference = preference
   }

   func transform(input: Input) -> Output {
      let watchlist = BehaviorRelay<[CurrencyPair]?>(value: nil)
      let watchlistError = BehaviorRelay<Error?>(value: nil)

      let watclistRequestDriver = preference.serviceProvider.repository.watchlist.watchlist()
         .readResult()
         .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
         .do(onNext: { result in
            switch result.flattened {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     guard let currencyPairs = coordinator.watchList?.currencyPairs else {
                        break
                     }

                     watchlistError.accept(nil)
                     watchlist.accept(Array(currencyPairs.prefix(5)))
                  default:
                     break
                  }
               }
            case let .failure(failure):
               switch failure {
               case let .error(error):
                  watchlistError.accept(error)
               default:
                  break
               }
            default:
               break
            }
         })
         .void()

      let getCurrencyDetailsAction = preference.serviceProvider.repository.prices.currencyDetail

      let loadState = Driver.combineLatest(watchlist.asDriver(),
                                           watchlistError.asDriver()) { currencyPairs, _ -> LoadState in
         guard let currencyPairs = currencyPairs else {
            return LoadState.error
         }
         return currencyPairs.isEmpty ? LoadState.emptyWatchlist : LoadState.ready
      }

      return Output(watclistRequestDriver: watclistRequestDriver,
                    getCurrencyDetailsAction: getCurrencyDetailsAction,
                    watchlist: watchlist.asDriver().filterNil(),
                    loadState: loadState,
                    loadStateViewDidTap: input.loadStateViewTap)
   }
}
