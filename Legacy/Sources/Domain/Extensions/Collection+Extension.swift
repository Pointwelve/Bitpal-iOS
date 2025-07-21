//
//  Collection+Extension.swift
//  Domain
//
//  Created by Kok Hong Choo on 22/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
extension Collection {
   /// Returns the element at the specified index iff it is within bounds, otherwise nil.
   public subscript(safe index: Index) -> Iterator.Element? {
      return indices.contains(index) ? self[index] : nil
   }
}
