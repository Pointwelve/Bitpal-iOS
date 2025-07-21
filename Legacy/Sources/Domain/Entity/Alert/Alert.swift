//
//  Alert.swift
//  Domain
//
//  Created by James Lai on 17/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct Alert: Equatable, RequestType {
   public let id: String
   public let base: String
   public let quote: String
   public let exchange: String
   public let comparison: AlertComparison
   public let reference: Decimal
   public let isEnabled: Bool

   public var pair: String {
      return "\(base)_\(quote)"
   }

   public init(id: String,
               base: String,
               quote: String,
               exchange: String,
               comparison: AlertComparison,
               reference: Decimal,
               isEnabled: Bool) {
      self.id = id
      self.base = base
      self.quote = quote
      self.exchange = exchange
      self.comparison = comparison
      self.reference = reference
      self.isEnabled = isEnabled
   }
}
