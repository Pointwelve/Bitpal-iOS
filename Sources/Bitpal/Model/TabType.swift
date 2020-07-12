//
//  TabType.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

enum TabType: String {
   case watchlist
   case alerts
   case settings

   static let all: [TabType] = [.watchlist, .alerts, .settings]

   /// Name presented in the title bar.
   var screenName: String {
      switch self {
      case .watchlist:
         return "watchlist.title".localized()
      case .alerts:
         return "alerts.title".localized()
      case .settings:
         return "settings.title".localized()
      }
   }

   /// Name presented in the tab bar.
   var tabName: String {
      switch self {
      case .watchlist:
         return "watchlist.title".localized()
      case .alerts:
         return "alerts.title".localized()
      case .settings:
         return "settings.title".localized()
      }
   }

   /// Image presented in the tab bar.
   var tabIcon: Image {
      switch self {
      case .watchlist:
         return .watchlist
      case .alerts:
         return .alerts
      case .settings:
         return .settings
      }
   }

   /// Accessibility Id for tab
   var tabAccessibilityId: AccessibilityIdentifier {
      switch self {
      case .watchlist:
         return .watchlistTab
      case .alerts:
         return .alertsTab
      case .settings:
         return .settingsTab
      }
   }

   /// Returns `TabRootNavigatorType` type.
   var tabNavigatorType: TabRootNavigatorType.Type {
      switch self {
      case .watchlist:
         return WatchlistNavigator.self
      case .alerts:
         return AlertsNavigator.self
      case .settings:
         return SettingsNavigator.self
      }
   }
}
