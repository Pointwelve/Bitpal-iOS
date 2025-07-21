//
//  DomainConvertible.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol DomainConvertible {
   associatedtype DomainType

   /// Converts object from `Data` to `Domain` layer.
   func asDomain() -> DomainType
}

extension Sequence where Iterator.Element: DomainConvertible {
   func asDomain() -> [Iterator.Element.DomainType] {
      return map { $0.asDomain() }
   }
}
