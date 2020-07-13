//
//  String+Extensions.swift
//  Domain
//
//  Created by Ryne Cheow on 13/1/18.
//  Copyright © 2018 Pointwelve. All rights reserved.
//

import Foundation

public extension String {
   func index(from: Int) -> Index {
      return index(startIndex, offsetBy: from)
   }

   func substring(from: Int) -> String {
      let fromIndex = index(from: from)
      return String(self[fromIndex...])
   }

   func substring(to: Int) -> String {
      let toIndex = index(from: to)
      return String(self[..<toIndex])
   }

   func substring(with r: Range<Int>) -> String {
      let startIndex = index(from: r.lowerBound)
      let endIndex = index(from: r.upperBound)
      return String(self[startIndex..<endIndex])
   }

   func toLengthOf(length: Int) -> String {
      if length <= 0 {
         return self
      } else if let to = index(startIndex, offsetBy: length, limitedBy: endIndex) {
         return String(self[to...])

      } else {
         return ""
      }
   }

   var convertToDictionary: [String: Any]? {
      if let data = data(using: .utf8) {
         do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
         } catch {
            return nil
         }
      }
      return nil
   }
}

/*
 Boyer-Moore string search
 This code is based on the article "Faster String Searches" by Costas Menico
 from Dr Dobb's magazine, July 1989.
 http://www.drdobbs.com/database/faster-string-searches/184408171
 */

public extension String {
   func index(of pattern: String, usingHorspoolImprovement: Bool = false) -> Index? {
      // Cache the length of the search pattern because we're going to
      // use it a few times and it's expensive to calculate.
      let patternLength = pattern.count
      guard patternLength > 0, patternLength <= count else {
         return nil
      }

      // Make the skip table. This table determines how far we skip ahead
      // when a character from the pattern is found.
      var skipTable = [Character: Int]()
      for (i, c) in pattern.enumerated() {
         skipTable[c] = patternLength - i - 1
      }

      // This points at the last character in the pattern.
      let p = pattern.index(before: pattern.endIndex)
      let lastChar = pattern[p]

      // The pattern is scanned right-to-left, so skip ahead in the string by
      // the length of the pattern. (Minus 1 because startIndex already points
      // at the first character in the source string.)
      var i = index(startIndex, offsetBy: patternLength - 1)

      // This is a helper function that steps backwards through both strings
      // until we find a character that doesn’t match, or until we’ve reached
      // the beginning of the pattern.
      func backwards() -> Index? {
         var q = p
         var j = i
         while q > pattern.startIndex {
            j = index(before: j)
            q = index(before: q)
            if self[j] != pattern[q] {
               return nil
            }
         }
         return j
      }

      // The main loop. Keep going until the end of the string is reached.
      while i < endIndex {
         let c = self[i]

         // Does the current character match the last character from the pattern?
         if c == lastChar {
            // There is a possible match. Do a brute-force search backwards.
            if let k = backwards() {
               return k
            }

            if !usingHorspoolImprovement {
               // If no match, we can only safely skip one character ahead.
               i = index(after: i)
            } else {
               // Ensure to jump at least one character (this is needed because the first
               // character is in the skipTable, and `skipTable[lastChar] = 0`)
               let jumpOffset = max(skipTable[c] ?? patternLength, 1)
               i = index(i, offsetBy: jumpOffset, limitedBy: endIndex) ?? endIndex
            }
         } else {
            // The characters are not equal, so skip ahead. The amount to skip is
            // determined by the skip table. If the character is not present in the
            // pattern, we can skip ahead by the full pattern length. However, if
            // the character *is* present in the pattern, there may be a match up
            // ahead and we can't skip as far.
            i = index(i, offsetBy: skipTable[c] ?? patternLength, limitedBy: endIndex) ?? endIndex
         }
      }
      return nil
   }
}

public extension String {
   func matches(regex: String) -> Bool {
      // swiftlint:disable force_try
      let regex = try! NSRegularExpression(pattern: regex)
      let nsString = self as NSString
      let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
      return !results.map { nsString.substring(with: $0.range) }.isEmpty
   }
}