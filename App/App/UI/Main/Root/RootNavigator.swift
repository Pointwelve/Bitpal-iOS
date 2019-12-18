//
//  RootNavigator.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol RootNavigatorType: TabRootNavigatorType, ParentNavigatorType {}

/// Responsible for presenting tab view controller for main screen.

final class RootNavigator: RootNavigatorType {
   var children = ChildNavigators()
   var state: NavigationState!

   var tabType: TabType!

   func start() {
      let viewModel = RootViewModel(navigator: self)
      let viewController = RootViewController(viewModel: viewModel)
      state.navigationController?.pushViewController(viewController, animated: false)
   }

   func finish() {}
}
