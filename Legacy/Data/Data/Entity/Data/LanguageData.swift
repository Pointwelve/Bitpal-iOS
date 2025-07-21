//
//  LanguageData.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct LanguageData: DataType, Equatable {
   let code: String

   // swiftlint:disable force_try
   static let `default` = try! LanguageData(code: Language.default.rawValue)

   init(code: String) throws {
      guard Language(rawValue: code) != nil else {
         throw ParseError.parseFailed
      }
      self.code = code
   }
}
