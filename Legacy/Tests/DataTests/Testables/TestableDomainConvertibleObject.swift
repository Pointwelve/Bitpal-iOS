//
//  TesableDomainConvertible.swift
//  Data
//
//  Created by Alvin Choo on 26/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Domain
import Foundation

struct TestableDomainConvertedObject: Equatable {
   let test: String
}

struct TestableDomainConvertibleObject: Equatable {
   let test: String
}

extension TestableDomainConvertibleObject: DomainConvertible {
   typealias DomainType = TestableDomainConvertedObject

   func asDomain() -> TestableDomainConvertedObject {
      return TestableDomainConvertedObject(test: test)
   }
}
