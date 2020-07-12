//
//  SplashNavigator.swift
//  App
//
//  Created by Li Hao Lai on 26/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol SplashNavigatorType: ParentNavigatorType {}

final class SplashNavigator: SplashNavigatorType {
   var children = ChildNavigators()
   var state: NavigationState!

   func start() {}
}
