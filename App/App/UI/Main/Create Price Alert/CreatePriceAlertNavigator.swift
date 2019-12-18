//
//  CreatePriceAlertNavigator.swift
//  App
//
//  Created by James Lai on 5/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import Presentr

protocol CreatePriceAlertNavigatorType: ParentNavigatorType {
   var currencyPairDetail: CurrencyDetail! { get set }
   var presentr: Presentr! { get set }
   func dismissCreatePriceAlert()
}

final class CreatePriceAlertNavigator: CreatePriceAlertNavigatorType {
   var children = ChildNavigators()
   var state: NavigationState!
   var currencyPairDetail: CurrencyDetail!
   var presentr: Presentr!
   var completion: (() -> Void)!

   func start() {
      let viewModel = CreatePriceAlertViewModel(navigator: self)
      let viewController = CreatePriceAlertViewController(viewModel: viewModel)
      state.navigationController?.customPresentViewController(presentr,
                                                              viewController: viewController,
                                                              animated: true,
                                                              completion: nil)
   }

   func finish() {
      state.navigationController?.dismiss(animated: true, completion: completion)
   }

   func dismissCreatePriceAlert() {
      state?.parent?.finish(child: self)
   }
}
