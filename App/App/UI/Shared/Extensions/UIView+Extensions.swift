//
//  UIView+Extensions.swift
//  App
//
//  Created by Li Hao Lai on 25/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

extension UIView {
   var safeLeadingAnchor: NSLayoutXAxisAnchor {
      if #available(iOS 11.0, *) {
         return safeAreaLayoutGuide.leadingAnchor
      } else {
         return leadingAnchor
      }
   }

   var safeTrailingAnchor: NSLayoutXAxisAnchor {
      if #available(iOS 11.0, *) {
         return safeAreaLayoutGuide.trailingAnchor
      } else {
         return trailingAnchor
      }
   }

   var safeTopAnchor: NSLayoutYAxisAnchor {
      if #available(iOS 11.0, *) {
         return safeAreaLayoutGuide.topAnchor
      } else {
         return topAnchor
      }
   }

   var safeBottomAnchor: NSLayoutYAxisAnchor {
      if #available(iOS 11.0, *) {
         return safeAreaLayoutGuide.bottomAnchor
      } else {
         return bottomAnchor
      }
   }
}
