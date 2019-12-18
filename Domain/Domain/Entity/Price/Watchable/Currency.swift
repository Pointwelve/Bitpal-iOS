//
//  Currency.swift
//  Domain
//
//  Created by Hong on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct Currency: DomainType, Equatable, Hashable {
   public let id: String
   public let name: String
   public let symbol: String

   public init(id: String, name: String, symbol: String) {
      self.id = id
      self.name = name
      self.symbol = symbol
   }

   public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
   }
}
