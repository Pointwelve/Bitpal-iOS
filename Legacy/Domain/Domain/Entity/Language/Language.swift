//
//  Language.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum Language: String, DomainType {
   /// English
   case en
   /// French
   case fr
   /// German
   case de

   public static let `default`: Language = .en

   public init(code: String) {
      self = Language(rawValue: code) ?? .default
   }
}
