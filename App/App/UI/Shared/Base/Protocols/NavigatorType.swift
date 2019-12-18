//
//  NavigatorType.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

/// Responsible for navigating between screens.
protocol NavigatorType: class {
   /// Create a navigator.
   ///
   /// - Parameter state: State that navigator uses to understand its position in the user journey.
   init(state: NavigationState)

   init()

   /// Begin navigation flow.
   func start()

   /// Finish navigation flow.
   func finish()

   /// State that navigator uses to understand its position in the user journey.
   var state: NavigationState! { get set }
}

protocol CustomControllerNavigatorType {
   var customController: UIViewController? { get }
}

extension NavigatorType {
   init() {
      fatalError("start() has not been implemented")
   }

   init(state: NavigationState) {
      self.init()
      self.state = state
   }

   func finish() {}

   func cleanup() {}

   var controller: UIViewController? {
      if let custom = (self as? CustomControllerNavigatorType)?.customController {
         return custom
      }
      if let navigationController = state.navigationController {
         return navigationController
      }
      if let tabBarController = state.tabBarController {
         return tabBarController
      }
      return nil
   }
}
