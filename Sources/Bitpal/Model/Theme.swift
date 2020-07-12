//
//  Theme.swift
//  App
//
//  Created by Li Hao Lai on 3/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension Theme {
   /// Localized user-presentable name of the current language.
   var name: String {
      return "theme.\(rawValue)".localized()
   }
}
