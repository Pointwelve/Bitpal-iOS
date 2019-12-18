//
//  AlertsNavigator.swift
//  App
//
//  Created by James Lai on 10/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol AlertsNavigatorType: TabRootNavigatorType, ParentNavigatorType {}

final class AlertsNavigator: AlertsNavigatorType {
   var tabType: TabType!
   var children = ChildNavigators()
   var state: NavigationState!

   func start() {
      let viewModel = AlertsViewModel(navigator: self)
      let viewController = AlertsViewController(viewModel: viewModel)
      state.navigationController?.pushViewController(viewController, animated: true)
      if #available(iOS 11.0, *) {
         state.navigationController?.navigationBar.prefersLargeTitles = true
      }
   }

   func finish() {}
}
