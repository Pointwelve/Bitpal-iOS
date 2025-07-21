//
//  Result+Extensions.swift
//  App
//
//  Created by Ryne Cheow on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct SuppressionOptions: OptionSet {
   let rawValue: Int

   static let loading = SuppressionOptions(rawValue: 1 << 0)
   static let error = SuppressionOptions(rawValue: 1 << 1)
}

extension Result where T == Void {
   mutating func suppress(_ options: SuppressionOptions = .error) {
      self = suppressing(options)
   }

   func suppressing(_ options: SuppressionOptions = .error) -> Result<Void> {
      switch self {
      case .content(.with(_, .loading)) where options.contains(.loading),
           .failure(.error) where options.contains(.error):
         return .content(.with((), .full))
      default:
         return self
      }
   }
}
