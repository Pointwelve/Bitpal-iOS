//
//  Exchange+Localized.swift
//  App
//
//  Created by Ryne Cheow on 5/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain

extension Exchange {
   public var localizedFullname: String {
      return name.localized()
   }
}
