//
//  TermsAndConditionsNavigator.swift
//  App
//
//  Created by James Lai on 27/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol TermsAndConditionsNavigatorType: NavigatorType {}

final class TermsAndConditionsNavigator: TermsAndConditionsNavigatorType {
   var state: NavigationState!

   func start() {
      let viewModel = TermsAndConditionsViewModel(navigator: self)
      let viewController = TermsAndConditionsViewController(viewModel: viewModel)
      state.navigationController?.pushViewController(viewController, animated: true)
   }

   func finish() {}
}
