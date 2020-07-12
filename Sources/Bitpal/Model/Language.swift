//
//  Language.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

extension Language {
   /// Localized user-presentable name of the current language.
   var name: String {
      return "language.\(rawValue)".localized()
   }
}
