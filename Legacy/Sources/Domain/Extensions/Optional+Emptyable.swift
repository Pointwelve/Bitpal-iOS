//
//  Optional+Emptyable.swift
//  Domain
//
//  Created by Ryne Cheow on 23/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

extension String: Emptyable {}

extension Optional: Emptyable {
   public var isEmpty: Bool {
      guard let value = self else {
         // Empty if null
         return true
      }
      guard let emptyable = value as? Emptyable else {
         // Error if object does not conform to protocol.
         fatalError("Object must adhere to protocol 'Emptyable'")
      }
      // Rely on object to specify whether it's value is empty or not.
      return emptyable.isEmpty
   }
}
