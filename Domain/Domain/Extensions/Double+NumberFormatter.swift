//
//  Double+NumberFormatter.swift
//  App
//
//  Created by Kok Hong Choo on 20/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
extension Double {
   public func formatUsingAbbrevation() -> String {
      let numFormatter = NumberFormatter()

      typealias Abbrevation = (threshold: Double, divisor: Double, suffix: String)
      let abbreviations: [Abbrevation] = [
         (0, 1, ""),
         (1000.0, 1000.0, "K"),
         (100_000.0, 1_000_000.0, "M"),
         (100_000_000.0, 1_000_000_000.0, "B")
      ]

      let startValue = Double(abs(self))
      let abbreviation: Abbrevation = {
         var prevAbbreviation = abbreviations[0]
         for tmpAbbreviation in abbreviations {
            if startValue < tmpAbbreviation.threshold {
               break
            }
            prevAbbreviation = tmpAbbreviation
         }
         return prevAbbreviation
      }()

      let value = Double(self) / abbreviation.divisor
      numFormatter.positiveSuffix = abbreviation.suffix
      numFormatter.negativeSuffix = abbreviation.suffix
      numFormatter.minimumIntegerDigits = 1
      numFormatter.usesSignificantDigits = true
      numFormatter.minimumSignificantDigits = 2
      numFormatter.maximumSignificantDigits = 6

      return numFormatter.string(from: NSNumber(value: value)) ?? ""
   }

   public func formatUsingSignificantDigits() -> String {
      let numFormatter = NumberFormatter()

      numFormatter.minimumIntegerDigits = 1
      numFormatter.usesSignificantDigits = true
      numFormatter.minimumSignificantDigits = 2
      numFormatter.maximumSignificantDigits = 6

      return numFormatter.string(from: NSDecimalNumber(value: self)) ?? ""
   }
}
