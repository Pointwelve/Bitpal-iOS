//
//  ThemeData.swift
//  Data
//
//  Created by Li Hao Lai on 5/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct ThemeData: DataType, Equatable {
   let name: String

   // swiftlint:disable force_try
   static let `default` = try! ThemeData(name: Theme.default.rawValue)

   init(name: String) throws {
      self.name = Theme(name: name).rawValue
   }
}
