//
//  NavigatorState.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Data
import Domain
import UIKit

protocol NavigationStateType {
   /// The application's `UIWindow`.
   /// Only present if `parent` is nil.
   var window: UIWindow? { get set }

   /// Navigation controller to use for navigating to screens.
   /// Only present if `window` is `nil`.
   var navigationController: BaseNavigationController? { get set }

   /// Tab controller to use for navigating between screens.
   /// Only present if `window` is `nil`.
   var tabBarController: UITabBarController? { get set }

   /// `ParentNavigatorType` which can be used for passing information back.
   /// Only present if `window` is `nil`.
   var parent: ParentNavigatorType? { get set }

   /// User's application preferences containing useful information to pass between screens.
   var preferences: AppPreferencesType { get }
}

/// State object that is passed between navigators.
struct NavigationState: NavigationStateType {
   /// The application's `UIWindow`.
   /// Only present if `parent` is nil.
   weak var window: UIWindow?

   /// Navigation controller to use for navigating to screens.
   /// Only present if `window` is `nil`.
   weak var navigationController: BaseNavigationController?

   /// Tab controller to use for navigating between screens.
   /// Only present if `window` is `nil`.
   weak var tabBarController: UITabBarController?

   /// `ParentNavigatorType` which can be used for passing information back.
   /// Only present if `window` is `nil`.
   weak var parent: ParentNavigatorType?

   /// User's application preferences containing useful information to pass between screens.
   var preferences: AppPreferencesType

   /// Initializer for root navigation structures where the only parent is an `UIWindow`.
   ///
   /// - Parameters:
   ///   - window: The application's `UIWindow`.
   ///   - preferences: User preferences (such as language).
   init(window: UIWindow?,
        preferences: AppPreferencesType) {
      self.window = window
      navigationController = nil
      tabBarController = nil
      self.preferences = preferences
      parent = nil
   }

   /// Initializer for child navigation structures.
   ///
   /// - Parameters:
   ///   - parent: `ParentNavigatorType` which can be used for passing information back.
   ///   - navigationController: (Optional) Navigation controller to
   /// use for navigating to screens. If omitted, parent navigation controller will be used.
   ///   - preferences: (Optional) User preferences (such as language). If omitted, parent preferences will be used.
   init(parent: ParentNavigatorType,
        navigationController: BaseNavigationController? = nil,
        preferences: AppPreferencesType? = nil) {
      window = nil
      self.navigationController = navigationController ?? parent.state.navigationController
      tabBarController = nil
      self.parent = parent
      self.preferences = preferences ?? parent.state.preferences
   }

   /// Initializer for tab navigation structures.
   ///
   /// - Parameters:
   ///   - parent: Parent `NavigatorType` which can be used for passing information back.
   ///   - preferences: User preferences (such as language).
   init(parent: ParentNavigatorType, preferences: AppPreferencesType) {
      window = nil
      navigationController = nil
      tabBarController = nil
      self.parent = parent
      self.preferences = preferences
   }

   /// Initializer for tabbed child navigation structures.
   ///
   /// - Parameters:
   ///   - parent: Parent `NavigatorType` which can be used for passing information back.
   ///   - tabBarController: Tab controller to use for navigating between screens.
   ///   - preferences: (Optional) User preferences (such as language). If omitted, parent preferences will be used.
   init(parent: ParentNavigatorType, tabBarController: UITabBarController, preferences: AppPreferencesType? = nil) {
      window = nil
      navigationController = nil
      self.parent = parent
      self.preferences = preferences ?? parent.state.preferences
      self.tabBarController = tabBarController
   }
}

extension NavigationState {
   /// Get ancestor state which consist of presenting window
   ///
   /// - Returns: Navigation state that contains a presenting window
   func rootState() -> NavigationState? {
      if window != nil {
         return self
      }

      if let parentState = self.parent?.state {
         return parentState.rootState()
      }

      return nil
   }
}
