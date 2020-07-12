//
//  Route.swift
//  App
//
//  Created by Li Hao Lai on 16/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

enum Route {
   // watchlist tab
   case watchlist
   case addCurrency
   case currencyDetails

   // alert tab
   case alerts

   // settings
   case termsAndConditions

   var deeplink: String {
      switch self {
      case .watchlist:
         return "/watchlist"

      case .addCurrency:
         return "/watchlist/add"

      case .currencyDetails:
         return "/watchlist/:exchange/:pairs"

      case .alerts:
         return "/alerts"

      case .termsAndConditions:
         return "/settings/terms"
      }
   }

   var tab: TabType {
      switch self {
      case .watchlist:
         return .watchlist

      case .addCurrency:
         return .watchlist

      case .currencyDetails:
         return .watchlist

      case .alerts:
         return .alerts

      case .termsAndConditions:
         return .settings
      }
   }

   static let routes: [Route] = [.watchlist, .addCurrency, .currencyDetails, .alerts, .termsAndConditions]
}
