//
//  CreditsNavigator.swift
//  App
//
//  Created by James Lai on 8/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol CreditsNavigatorType: NavigatorType {}

final class CreditsNavigator: CreditsNavigatorType {
   var state: NavigationState!

   func start() {
      let viewModel = CreditsViewModel(navigator: self)
      let viewController = CreditsViewController(viewModel: viewModel)
      state.navigationController?.pushViewController(viewController, animated: true)
   }

   func finish() {}
}
