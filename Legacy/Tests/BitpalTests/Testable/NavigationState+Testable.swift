//
//  NavigationState+Testable.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Bitpal
import Data
import Domain
import Foundation

// Testable extension of NavigationState
extension NavigationState {
   init(preferences: AppPreferencesType) {
      self.init(window: nil, preferences: preferences)
   }
}
