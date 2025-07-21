//
//  String+Localizable.swift
//  Domain
//
//  Created by Ryne Cheow on 4/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
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
