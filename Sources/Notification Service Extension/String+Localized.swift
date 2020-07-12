//
//  String+Localized.swift
//  Notification Service Extension
//
//  Created by Li Hao Lai on 5/2/18.
//  Copyright © 2018 Pointwelve. All rights reserved.
//

import Foundation

public extension String {
   func localized() -> String {
      return NSLocalizedString(self, comment: "")
   }

   func localizedFormat(arguments: CVarArg...) -> String {
      return String(format: localized(), arguments: arguments)
   }
}
