//
//  WatchlistNavigator.swift
//  App
//
//  Created by Hong on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

protocol WatchlistNavigatorType: TabRootNavigatorType, ParentNavigatorType, FatalErrorNavigatorType,
   ReloadableNavigatorType {
   func showWatchlistDetail(_ currencyPair: CurrencyPair)
   func showWatchlistAddCoin()
}

/// Responsible for presenting tab view controller for main screen.

final class WatchlistNavigator: WatchlistNavigatorType {
   var tabType: TabType!
   private let disposeBag = DisposeBag()
   var children = ChildNavigators()
   var state: NavigationState!

   var willBecomeVisible: SharedSequence<DriverSharingStrategy, Bool>!

   func start() {
      let viewModel = WatchlistViewModel(navigator: self)
      let viewController = WatchlistViewController(viewModel: viewModel)
      state.navigationController?.pushViewController(viewController, animated: false)
      if #available(iOS 11.0, *) {
         state.navigationController?.navigationBar.prefersLargeTitles = true
      }
   }

   func finish() {}

   func errorDismissed() {}

   func showWatchlistAddCoin() {
      let addCoinNavigator = WatchlistAddCoinNavigator(state: .init(parent: self))
      start(child: addCoinNavigator)
   }

   func showWatchlistDetail(_ currencyPair: CurrencyPair) {
      let watchlistDetailNavigator = WatchlistDetailNavigator(state: .init(parent: self))
      watchlistDetailNavigator.currencyPair = currencyPair
      start(child: watchlistDetailNavigator)
   }
}

extension WatchlistNavigator: Routable {
   func handle() {
      let routes = state.preferences.serviceProvider.routes

      routes.asDriver()
         .startWith(routes.value)
         .asDriver()
         .filterNil()
         .drive(onNext: { [weak self] routeDef in
            guard let `self` = self else { return }

            switch routeDef.route {
            case .addCurrency:
               guard self.children.navigators.last is WatchlistAddCoinNavigator else {
                  self.children.finishAll()
                  self.showWatchlistAddCoin()
                  break
               }
            case .currencyDetails:
               self.children.finishAll()

               guard let params = routeDef.params,
                  let rawExchange = params["exchange"],
                  let rawPairs = params["pairs"] else {
                  break
               }

               let rawBaseQuote = rawPairs.split(separator: "_").map { String($0) }

               guard rawBaseQuote.count == 2 else {
                  break
               }

               let request = "\(rawBaseQuote[0])\(rawBaseQuote[1])\(rawExchange)"
               self.state.preferences.serviceProvider.repository.currencyPair
                  .getCurrecnyPair(request: request)
                  .getResult()
                  .filter { $0.hasContent }
                  .map { $0.contentValue?.currencyPair }
                  .asDriver(onErrorJustReturn: nil)
                  .filterNil()
                  .drive(onNext: { [weak self] currencyPair in
                     self?.showWatchlistDetail(currencyPair)
                  })
                  .disposed(by: self.disposeBag)

            default:
               break
            }
         })
         .disposed(by: disposeBag)
   }
}
