//
//  HTTPHeaderField.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum HTTPHeaderField {
   case acceptLanguage(Language)
   case authorization(String)

   public var key: String {
      switch self {
      case .acceptLanguage: return "Accept-Language"
      case .authorization: return "Authorization"
      }
   }

   public var value: String {
      switch self {
      case let .authorization(token): return token
      case let .acceptLanguage(language): return language.rawValue
      }
   }
}

public extension URLRequest {
   mutating func adding(headerField: HTTPHeaderField) {
      addValue(headerField.value, forHTTPHeaderField: headerField.key)
   }

   mutating func adding(headerFields: [HTTPHeaderField]) {
      headerFields.forEach {
         self.addValue($0.value, forHTTPHeaderField: $0.key)
      }
   }
}
