//
//  AccessibilityIdentifier.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

enum AccessibilityIdentifier: String {
   case tabBar
   case settingsTab
   case alertsTab
   case watchlistTab

   // Watch List Cell
   case watchListCell
   case watchListBaseLabel
   case watchListQuoteLabel
   case watchListExchangeLabel
   case watchListPercentageView
   case watchListPercentageLabel
   case watchListGraphView
   case watchListPriceLabel

   case watchlistTitle
   case watchlistAddButton

   case loadStateErrorViewTitle
   case loadStateErrorViewMessage

   // Settings page
   case settingsNavigationTitle
   case settingsVersionLabel
   case settingsTable

   case settingsCellTitleLabel
   case settingsCellDescriptionLabel
   case settingsCellDisclosure

   case termsAndConditionCell
   case languageCell
   case styleCell
   case rateCell
   case creditsCell

   // Static content page
   case staticContentNavigationTitle
   case staticContentCompanyTitleLabel
   case staticContentTextView

   // Watch List Detail
   case watchlistDetailTitle
   case watchlistDetailPriceLabel
   case watchlistDetailPricePctLabel
   case watchlistDetailPriceDayLabel
   case watchlistDetailCandleStickChart
   case watchlistDetailLineChart

   // Alerts
   case alertsTitle

   // Add coin
   case selectExchangeTitle
}

extension UIAccessibilityIdentification {
   /// Set `accessibility` information.
   ///
   /// - Parameters:
   ///   - id: Identifier value.
   ///   - suffix: Optional identifier suffix.
   func setAccessibility(id: AccessibilityIdentifier, suffix: String = "") {
      // Set accessibility identifier with
      accessibilityIdentifier = id.rawValue
   }
}
