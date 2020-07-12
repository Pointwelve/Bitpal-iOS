//
//  Modifiable.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public protocol Modifiable {
   var modifyDate: Date { get set }
   var hasExpired: Bool { get }
}

extension Modifiable {
   public var hasExpired: Bool {
      return Date().timeIntervalSince(modifyDate) - cacheTimeout >= 0
   }
}

public protocol Sortable: Modifiable, Comparable {}

public extension Sortable {
   static func <(lhs: Self, rhs: Self) -> Bool {
      return lhs.modifyDate < rhs.modifyDate
   }

   static func >(lhs: Self, rhs: Self) -> Bool {
      return lhs.modifyDate > rhs.modifyDate
   }

   static func ==(lhs: Self, rhs: Self) -> Bool {
      return lhs.modifyDate == rhs.modifyDate
   }
}
