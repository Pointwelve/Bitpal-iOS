//
//  Bundle+Identifier.swift
//  App
//
//  Created by Kok Hong Choo on 21/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

extension Bundle {
   var versionString: String {
      guard let versionNumber = versionNumber, let buildNumber = buildNumber else {
         return ""
      }
      return "\(versionNumber) (\(buildNumber))"
   }

   fileprivate var versionNumber: String? {
      return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
   }

   fileprivate var buildNumber: String? {
      return object(forInfoDictionaryKey: "CFBundleVersion") as? String
   }
}
