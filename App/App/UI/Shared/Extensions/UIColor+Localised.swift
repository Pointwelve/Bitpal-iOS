//
//  UIColor+Localised.swift
//  App
//
//  Created by Ryne Cheow on 5/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

extension UIColor {
   convenience init(localisationKey: String) {
      self.init(localisationKey.localized())
   }
}
