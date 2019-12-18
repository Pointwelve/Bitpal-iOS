//
//  Sequence+Extensions.swift
//  Domain
//
//  Created by Ryne Cheow on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

extension Sequence where Iterator.Element: Equatable {
   /// Replaces an equatable item with a new value.
   /// Handy for replacing equatable objects with different values.
   public func replacing(value: Iterator.Element) -> [Iterator.Element] {
      return map { $0 != value ? $0 : value }
   }
}

extension Sequence where Iterator.Element == Language {
   public func mostSuitable(for language: Language) -> Language {
      return filter { $0 == language }.first ?? .default
   }
}

public extension Array {
   subscript(safe index: Int) -> Iterator.Element? {
      return Int(index) < count ? self[Int(index)] : nil
   }
}
