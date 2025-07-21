//
//  String+Attributed.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

extension String {
   func attributedString(withLetterSpacing spacing: CGFloat? = nil,
                         lineHeight: CGFloat? = nil,
                         textAlignment: NSTextAlignment? = nil,
                         textColor: UIColor? = nil,
                         font: UIFont? = nil) -> NSAttributedString {
      let att = NSAttributedString.attributes(withLetterSpacing: spacing,
                                              lineHeight: lineHeight,
                                              textAlignment: textAlignment,
                                              textColor: textColor,
                                              font: font)

      return .init(string: self, attributes: att)
   }
}

extension NSAttributedString {
   static func attributes(withLetterSpacing spacing: CGFloat? = nil,
                          lineHeight: CGFloat? = nil,
                          textAlignment: NSTextAlignment? = nil,
                          textColor: UIColor? = nil,
                          font: UIFont? = nil,
                          text: String? = nil) -> [NSAttributedString.Key: Any] {
      var attributes: [NSAttributedString.Key: Any] = [:]
      let style = NSMutableParagraphStyle()

      if let spacing = spacing {
         attributes[.kern] = spacing
      }

      if let lineHeight = lineHeight {
         style.minimumLineHeight = lineHeight
         attributes.updateValue(style, forKey: .paragraphStyle)
      }

      if let textAlignment = textAlignment {
         style.alignment = textAlignment
         attributes.updateValue(style, forKey: .paragraphStyle)
      }

      if let textColor = textColor {
         attributes[.foregroundColor] = textColor
      }

      if let font = font {
         attributes[.font] = font
      }

      return attributes
   }
}

func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
   // swiftlint:disable force_cast
   let a = lhs.mutableCopy() as! NSMutableAttributedString
   let b = rhs.mutableCopy() as! NSMutableAttributedString

   a.append(b)

   return a.copy() as! NSAttributedString
}

func +(lhs: NSAttributedString, rhs: String) -> NSAttributedString {
   // swiftlint:disable force_cast
   let a = lhs.mutableCopy() as! NSMutableAttributedString
   let b = NSMutableAttributedString(string: rhs)

   return a + b
}

func +(lhs: String, rhs: NSAttributedString) -> NSAttributedString {
   let a = NSMutableAttributedString(string: lhs)
   // swiftlint:disable force_cast
   let b = lhs.mutableCopy() as! NSMutableAttributedString

   return a + b
}

func +(lhs: NSAttributedString, rhs: UIImage) -> NSAttributedString {
   // swiftlint:disable force_cast
   let a = lhs.mutableCopy() as! NSMutableAttributedString
   let b = NSTextAttachment()
   b.image = rhs

   return a + b
}

func +(lhs: NSAttributedString, rhs: NSTextAttachment) -> NSAttributedString {
   // swiftlint:disable force_cast
   let a = lhs.mutableCopy() as! NSMutableAttributedString
   let b = NSAttributedString(attachment: rhs)

   return a + b
}

func +(lhs: NSTextAttachment, rhs: NSAttributedString) -> NSAttributedString {
   let a = NSAttributedString(attachment: lhs)
   // swiftlint:disable force_cast
   let b = rhs.mutableCopy() as! NSMutableAttributedString

   return a + b
}
