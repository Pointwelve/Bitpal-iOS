//
//  PopupData.swift
//  App
//
//  Created by Li Hao Lai on 27/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import UIKit

enum PopupData {
   case migration

   var title: NSAttributedString {
      switch self {
      case .migration:
         return NSAttributedString(string: "popup.migration.title".localized())
      }
   }

   var message: NSAttributedString {
      switch self {
      case .migration:
         let unattributedTitle = "popup.migration.message".localized()
         let string = NSMutableAttributedString(string: unattributedTitle)
         let boldFactor = "popup.migration.message.boldFactor".localized()

         let range = (unattributedTitle as NSString).range(of: boldFactor, options: .caseInsensitive)
         string.addAttribute(.font,
                             value: Font.bold14,
                             range: range)

         return string
      }
   }

   var cancel: String {
      switch self {
      case .migration:
         return "popup.migration.cancel".localized()
      }
   }

   var ok: String {
      switch self {
      case .migration:
         return "popup.migration.ok".localized()
      }
   }
}
