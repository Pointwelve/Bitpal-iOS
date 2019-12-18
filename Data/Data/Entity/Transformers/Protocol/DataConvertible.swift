//
//  DataConvertible.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol DataConvertible {
   associatedtype DataType

   /// Converts object from `Domain` to `Data` layer.
   func asData() -> DataType
}

extension Sequence where Iterator.Element: DataConvertible {
   func asData() -> [Iterator.Element.DataType] {
      return map { $0.asData() }
   }
}
