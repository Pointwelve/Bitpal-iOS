//
//  Exchange.swift
//  Domain
//
//  Created by Ryne Cheow on 31/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct Exchange: DomainType, Equatable, Hashable {
   public let name: String
   public let id: String

   public init(id: String, name: String) {
      self.id = id
      self.name = name
   }

   public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
   }
}
