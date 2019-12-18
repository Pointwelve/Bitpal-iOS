//
//  TabRootNavigatorType.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

/// Must be implemented by all tabs in the Main screen.

protocol TabRootNavigatorType: NavigatorType {
   var tabType: TabType! { get set }
   init(state: NavigationState, tabType: TabType)
}

extension TabRootNavigatorType {
   init(state: NavigationState, tabType: TabType) {
      self.init(state: state)
      self.tabType = tabType
   }
}
