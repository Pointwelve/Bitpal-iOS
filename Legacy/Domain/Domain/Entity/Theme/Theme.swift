//
//  Theme.swift
//  Domain
//
//  Created by Li Hao Lai on 31/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum Theme: String, DomainType {
   /// dark theme
   case dark
   /// light theme
   case light

   fileprivate enum Key: String {
      case theme = "Theme"
   }

   fileprivate var analyticsValue: String {
      switch self {
      case .dark:
         return "Dark"

      case .light:
         return "Light"
      }
   }

   public var analyticsMetadata: [String: Any] {
      return [Key.theme.rawValue: self.analyticsValue]
   }

   public static let `default` = Theme.dark

   public init(name: String) {
      self = Theme(rawValue: name) ?? .default
   }

   public static let identifier = "BitpalCurrentThemeNameKey"
}
