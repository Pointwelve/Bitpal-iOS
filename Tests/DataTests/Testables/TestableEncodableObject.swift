//
//  TestableEncodableObject.swift
//  Data
//
//  Created by Ryne Cheow on 5/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

class TestableEncodableObject: NSObject, NSCoding {
   var objectName = "Name"
   var objectProperty = 0

   override init() {}

   required init?(coder decoder: NSCoder) {
      if let name = decoder.decodeObject(forKey: "objectName") as? String {
         objectName = name
      }

      objectProperty = decoder.decodeInteger(forKey: "objectRating")
   }

   func encode(with encoder: NSCoder) {
      encoder.encode(objectName, forKey: "objectName")
      encoder.encode(objectProperty, forKey: "objectRating")
   }
}
