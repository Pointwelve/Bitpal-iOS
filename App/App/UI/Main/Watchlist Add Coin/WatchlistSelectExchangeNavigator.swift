//
//  WatchlistSelectExchangeNavigator.swift
//  App
//
//  Created by Li Hao on 19/1/18.
//  Copyright © 2018 Pointwelve. All rights reserved.
//

import Domain
import Foundation

protocol WatchlistSelectExchangeNavigatorType: FatalErrorNavigatorType {}

final class WatchlistSelectExchangeNavigator: WatchlistSelectExchangeNavigatorType {
   var state: NavigationState!
   var currencyPairGroup: CurrencyPairGroup!

   func start() {
      let viewModel = WatchlistSelectExchangeViewModel(navigator: self)
      let viewController = WatchlistSelectExchangeViewController(viewModel: viewModel)
      state.navigationController?.pushViewController(viewController, animated: false)
   }

   func finish() {
      state.navigationController?.popToRootViewController(animated: true)
   }

   func errorDismissed() {}

   func dimissSelectExchange() {
      state.parent?.finish(child: self)
   }
}
