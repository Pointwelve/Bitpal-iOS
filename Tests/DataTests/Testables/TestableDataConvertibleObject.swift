//
//  TestableDataConvertibleObject.swift
//  Data
//
//  Created by Alvin Choo on 25/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Data
import Foundation

struct TestableDataConvertedObject: Equatable {
   let test: String
}

struct TestableDataConvertibleObject: Equatable {
   let test: String
}

extension TestableDataConvertibleObject: DataConvertible {
   typealias DataType = TestableDataConvertedObject

   func asData() -> TestableDataConvertedObject {
      return TestableDataConvertedObject(test: test)
   }
}
