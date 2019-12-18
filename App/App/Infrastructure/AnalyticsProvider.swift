//
//  AnalyticsProvider.swift
//  App
//
//  Created by Li Hao Lai on 17/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Fabric
import Firebase
import Foundation

final class AnalyticsProvider {
   static func log(login method: String, metadata: [String: Any]? = nil) {
      #if DEBUG
      #else
         // Fabric
         Answers.logLogin(withMethod: method,
                          success: true,
                          customAttributes: metadata)

         // Firebase / Google Analytics
         Analytics.logEvent(method.replacingOccurrences(of: " ", with: "_").lowercased(), parameters: metadata)
      #endif
   }

   static func log(event name: String, metadata: [String: Any]? = nil) {
      #if DEBUG
      #else
         // Fabric
         Answers.logCustomEvent(withName: name,
                                customAttributes: metadata)

         // Firebase / Google Analytics
         Analytics.logEvent(name.replacingOccurrences(of: " ", with: "_").lowercased(), parameters: metadata)
      #endif
   }
}
