//
//  NSLayoutConstraint+Extensions.swift
//  App
//
//  Created by Ryne Cheow on 13/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
   func constraint(withPriority priority: UILayoutPriority) -> NSLayoutConstraint {
      self.priority = priority
      return self
   }
}
