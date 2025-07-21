//
//  WatchlsitAddCoinNavigator.swift
//  App
//
//  Created by Li Hao Lai on 25/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

protocol WatchlistAddCoinNavigatorType: FatalErrorNavigatorType, ParentNavigatorType {}

final class WatchlistAddCoinNavigator: WatchlistAddCoinNavigatorType {
   var state: NavigationState!
   var children = ChildNavigators()

   func start() {
      let viewModel = WatchlistAddCoinViewModel(navigator: self)
      let viewController = WatchlistAddCoinViewController(viewModel: viewModel)
      state.navigationController?.pushViewController(viewController, animated: false)
   }

   func finish() {
      state.navigationController?.popViewController(animated: true)
   }

   func errorDismissed() {}

   func dimissWatchlistAddCoin() {
      state.parent?.finish(child: self)
   }

   func showSelectExchange(with currencyPairGroup: CurrencyPairGroup) {
      let watchlistSelectExchangeNavigator = WatchlistSelectExchangeNavigator(state: state)
      watchlistSelectExchangeNavigator.currencyPairGroup = currencyPairGroup

      start(child: watchlistSelectExchangeNavigator)
   }
}
