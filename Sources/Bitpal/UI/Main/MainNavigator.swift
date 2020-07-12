//
//  MainNavigator.swift
//  App
//
//  Created by Ryne Cheow on 21/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

/// Responsible for presenting tab view controller for main screen.
final class MainNavigator: NSObject, ParentNavigatorType {
   var children = ChildNavigators()
   var state: NavigationState!
   let disposeBag = DisposeBag()

   func start() {
      // Set self as delegate
      state.tabBarController?.delegate = self

      // Create navigators for each tab.
      TabType.all.forEach { tabType in
         let tabState = NavigationState(parent: self,
                                        tabBarController: state.tabBarController!,
                                        preferences: state.preferences)
         let tabNavigator = MainTabNavigator(state: tabState, tabType: tabType)
         start(child: tabNavigator)
      }
   }
}

extension MainNavigator: UITabBarControllerDelegate {}

extension MainNavigator: Routable {
   func select(tab tabType: TabType) {
      guard let index = TabType.all.firstIndex(of: tabType) else {
         return
      }

      state.tabBarController?.selectedIndex = index
   }

   func handle() {
      let routes = state.preferences.serviceProvider.routes

      routes.asDriver()
         .startWith(routes.value)
         .asDriver()
         .filterNil()
         .drive(onNext: { [weak self] routeDef in
            guard let `self` = self else {
               return
            }

            self.select(tab: routeDef.route.tab)
         })
         .disposed(by: disposeBag)
   }
}
