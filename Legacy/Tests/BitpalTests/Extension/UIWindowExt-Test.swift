//
//  UIWindowExt-Test.swift
//  App
//
//  Created by Alvin Choo on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import XCTest

class UIWindowExt_Test: XCTestCase {
   override func setUp() {
      super.setUp()
      // Put setup code here. This method is called before the invocation of each test method in the class.
   }

   override func tearDown() {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
      super.tearDown()
   }

   func testVisibleViewControllerNavigationController() {
      let window = UIApplication.shared.delegate?.window!

      let viewcontroller = UIViewController()
      let navigationController = UINavigationController(rootViewController: viewcontroller)

      window?.rootViewController = navigationController
      XCTAssertNotNil(window?.visibleViewController)
      XCTAssertTrue(viewcontroller == window?.visibleViewController)
   }

   func testVisibleViewControllerTabBarController() {
      let window = UIApplication.shared.delegate?.window!

      let viewcontroller = UIViewController()
      let tabBarController = UITabBarController()
      tabBarController.setViewControllers([viewcontroller], animated: false)

      window?.rootViewController = tabBarController
      XCTAssertNotNil(window?.visibleViewController)
      XCTAssertTrue(viewcontroller == window?.visibleViewController)
   }

   func testVisibleViewControllerPresentedController() {
      let window = UIApplication.shared.delegate?.window!

      let viewController = UIViewController()
      let presentedViewController = UIViewController()

      window?.rootViewController = viewController
      viewController.present(presentedViewController, animated: false, completion: nil)

      XCTAssertNotNil(window?.visibleViewController)
      XCTAssertTrue(presentedViewController == window?.visibleViewController)
   }

   func testVisibleViewControllerNormalViewController() {
      let window = UIApplication.shared.delegate?.window!

      let viewController = UIViewController()

      window?.rootViewController = viewController

      XCTAssertNotNil(window?.visibleViewController)
      XCTAssertTrue(viewController == window?.visibleViewController)
   }
}
