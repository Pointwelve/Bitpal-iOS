//
//  String+Attributed.swift
//  SEED
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Tigerspike. All rights reserved.
//

import UIKit

extension String {
   func attributedString(withLetterSpacing spacing: Style.LetterSpacing? = nil,
                         lineHeight: Style.LineHeight? = nil,
                         textAlignment: NSTextAlignment? = nil,
                         textColor: UIColor? = nil) -> NSAttributedString {
      var attributes: [String: Any] = [:]
      let style = NSMutableParagraphStyle()

      if let spacing = spacing {
         attributes[NSKernAttributeName] = spacing.rawValue
      }

      if let lineHeight = lineHeight {
         style.minimumLineHeight = lineHeight.rawValue
         attributes.updateValue(style, forKey: NSParagraphStyleAttributeName)
      }

      if let textAlignment = textAlignment {
         style.alignment = textAlignment
         attributes.updateValue(style, forKey: NSParagraphStyleAttributeName)
      }

      if let textColor = textColor {
         attributes[NSForegroundColorAttributeName] = textColor
      }

      return .init(string: self, attributes: attributes)
   }
}
