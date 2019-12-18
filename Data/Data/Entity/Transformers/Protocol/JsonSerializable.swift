//
//  JsonSerializable.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol Serializable {
   associatedtype Input
   associatedtype Output

   func serialized() -> Input

   static func deserialize(data: Input) throws -> Output
}
