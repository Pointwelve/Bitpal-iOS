//
//  AlertComparison.swift
//  Domain
//
//  Created by James Lai on 17/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum AlertComparison: String, DomainType {
   case greaterThanOrEqual

   case lessThanOrEqual

   public var symbol: String {
      switch self {
      case .greaterThanOrEqual:
         return "≥"

      case .lessThanOrEqual:
         return "≤"
      }
   }

   public var description: String {
      switch self {
      case .greaterThanOrEqual:
         return "alertComparison.greaterThanOrEqual.description".localized()

      case .lessThanOrEqual:
         return "alertComparison.lessThanOrEqual.description".localized()
      }
   }
}
