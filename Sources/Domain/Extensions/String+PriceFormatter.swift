//
//  String+PriceFormatter.swift
//  Domain
//
//  Created by Li Hao Lai on 11/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public extension String {
   func format(_ latestValidPrice: String?, maxLength: Int, maxSignificant: Int) -> String? {
      guard !isEmpty else {
         return ""
      }

      let regex = NSPredicate(format: "SELF MATCHES %@", "[0-9]+.?[0-9]{0,\(maxSignificant)}")

      guard regex.evaluate(with: self),
         count <= maxLength else {
         return latestValidPrice
      }

      return self
   }
}
