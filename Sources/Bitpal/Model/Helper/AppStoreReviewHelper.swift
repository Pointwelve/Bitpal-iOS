//
//  AppStoreReviewHelper.swift
//  App
//
//  Created by Ryne Cheow on 22/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

final class AppStoreReviewHelper {
   static func navigateUserForReview() {
      let itunesUrlString = "itms-apps://itunes.apple.com/us/app/bitpal/id1258167840?mt=8&action=write-review"
      guard let url = URL(string: itunesUrlString) else {
         return
      }
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
      #if DEBUG
      #else
         AnalyticsProvider.log(event: "Navigated to App Review")
      #endif
   }
}
