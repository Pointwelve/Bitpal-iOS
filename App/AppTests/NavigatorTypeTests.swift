//
//  NavigatorTypeTests.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import Domain
import RxSwift
import UIKit
import XCTest

class NavigatorTypeTests: XCTestCase {
   func testNavigatorTypeMakeChildNavigationState() {
      let preferences = TestableAppPreferences()

      // Create root navigator
      let rootNavigationState = NavigationState(window: UIWindow(),
                                                preferences: preferences)
      let rootNavigator = AppNavigator(state: rootNavigationState)

      // Create parent navigator
      let parentNavigationController = BaseNavigationController(nibName: nil, bundle: nil)
      let parentNavigationState = NavigationState(parent: rootNavigator,
                                                  navigationController: parentNavigationController,
                                                  preferences: preferences)
      let parentNavigator = RootNavigator(state: parentNavigationState)

      // Create child navigation state
      let childNavigationState = NavigationState(parent: parentNavigator)

      // Ensure values match parent
      let childParent = childNavigationState.parent
      let childPreferences = childNavigationState.preferences as! TestableAppPreferences
      let childNavigationController = childNavigationState.navigationController

      XCTAssertTrue(parentNavigator === childParent)
      XCTAssertEqual(parentNavigationController, childNavigationController)
      XCTAssertTrue(preferences === childPreferences)
   }
}
