//
//  WatchlistDetailNavigator.swift
//  App
//
//  Created by Kok Hong Choo on 13/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import Presentr

protocol WatchlistDetailNavigatorType: ParentNavigatorType {
   var currencyPair: CurrencyPair! { get set }
   func dismissWatchlistDetail()
   func showCreatePriceAlert(with currencyPairDetail: CurrencyDetail,
                             presentr: Presentr,
                             completion: @escaping () -> Void)
}

final class WatchlistDetailNavigator: WatchlistDetailNavigatorType {
   var children = ChildNavigators()
   var state: NavigationState!
   var currencyPair: CurrencyPair!

   private var navigationController: BaseNavigationController?

   func start() {
      let viewController = WatchlistDetailViewController(viewModel: .init(navigator: self))
      navigationController = BaseNavigationController(rootViewController: viewController)

      guard let navigationController = navigationController else {
         return
      }

      Style.NavigationBar.noHairline.apply(to: navigationController.navigationBar)

      DispatchQueue.main.async { [weak self] in
         self?.state.navigationController?.customPresentViewController(Presentr.watchlistDetailPresenter,
                                                                       viewController: navigationController,
                                                                       animated: true,
                                                                       completion: nil)
      }
   }

   func finish() {
      state.navigationController?.dismiss(animated: true, completion: nil)
   }

   func dismissWatchlistDetail() {
      state?.parent?.finish(child: self)
   }

   func errorDismissed() {}

   func showCreatePriceAlert(with currencyPairDetail: CurrencyDetail,
                             presentr: Presentr,
                             completion: @escaping () -> Void) {
      let createPriceAlertNavigator =
         CreatePriceAlertNavigator(state: .init(parent: self,
                                                navigationController: navigationController))
      createPriceAlertNavigator.currencyPairDetail = currencyPairDetail
      createPriceAlertNavigator.presentr = presentr
      createPriceAlertNavigator.completion = completion
      start(child: createPriceAlertNavigator)
   }
}
