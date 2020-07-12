//
//  UIWindow+Extension.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import UIKit

public extension UIWindow {
   /// Get the top most view controller on the current UIWindow instance
   var visibleViewController: UIViewController? {
      return UIWindow.visibleViewController(from: rootViewController)
   }

   /// Get visible controller recursively
   ///
   /// - Parameter viewController: view controller to find it's top view controller from
   /// - Returns: top most view controller
   private static func visibleViewController(from viewController: UIViewController?) -> UIViewController? {
      if let navigationController = viewController as? UINavigationController {
         return UIWindow.visibleViewController(from: navigationController.visibleViewController)
      }

      if let tabBarController = viewController as? UITabBarController {
         return UIWindow.visibleViewController(from: tabBarController.selectedViewController)
      }

      if let presentedViewController = viewController?.presentedViewController {
         return UIWindow.visibleViewController(from: presentedViewController)
      }

      return viewController
   }
}
