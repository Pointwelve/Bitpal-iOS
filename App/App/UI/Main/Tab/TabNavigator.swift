//
//  TabNavigator.swift
//  App
//
//  Created by Ryne Cheow on 21/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

/// Responsible for calling `start()` on a particular tab's navigator and adding the
/// navigation controller to the tab bar controller.
final class MainTabNavigator: ParentNavigatorType, TabRootNavigatorType {
   var tabType: TabType!
   var children = ChildNavigators()
   var state: NavigationState!

   private let disposeBag = DisposeBag()

   func start() {
      let tabViewModel = TabViewModel(navigator: self)
      let tabNavigationController = TabNavigationController(viewModel: tabViewModel, tabType: tabType)

      // Create root navigator which will create the view controller the navigation controller will use as it's root.
      let tabState = NavigationState(parent: self,
                                     navigationController: tabNavigationController,
                                     preferences: state.preferences)
      let tabNavigator = tabType.tabNavigatorType.init(state: tabState, tabType: tabType)
      start(child: tabNavigator)

      // Add navigation controller to tab bar controller
      let newControllers = (state.tabBarController?.viewControllers ?? []) + [tabNavigationController]
      state.tabBarController?.setViewControllers(newControllers, animated: false)
   }

   private func popToRootController(tabNavigationController: BaseNavigationController,
                                    tabNavigator: TabRootNavigatorType) {
      tabNavigationController.sequentialDismiss(animated: false, completion: {
         tabNavigationController.popToRootViewController(animated: false)

         // Keep root, purge children
         (tabNavigator as? ParentNavigatorType)?
            .children
            .navigators
            .compactMap { $0 as? ParentNavigatorType }
            .forEach { $0.children.purge() }
      })
   }
}
