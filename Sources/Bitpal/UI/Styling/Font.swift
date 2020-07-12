//
//  Font.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import UIKit

enum Font {
   private enum Nunito {
      static func extraLight(ofSize size: CGFloat) -> UIFont {
         return UIFont(name: "Nunito-ExtraLight", size: size)!
      }

      static func light(ofSize size: CGFloat) -> UIFont {
         return UIFont(name: "Nunito-Light", size: size)!
      }

      static func regular(ofSize size: CGFloat) -> UIFont {
         return UIFont(name: "Nunito-Regular", size: size)!
      }

      static func semiBold(ofSize size: CGFloat) -> UIFont {
         return UIFont(name: "Nunito-SemiBold", size: size)!
      }

      static func bold(ofSize size: CGFloat) -> UIFont {
         return UIFont(name: "Nunito-Bold", size: size)!
      }

      static func extraBold(ofSize size: CGFloat) -> UIFont {
         return UIFont(name: "Nunito-ExtraBold", size: size)!
      }
   }

   static let light9 = Nunito.light(ofSize: 9)
   static let light14 = Nunito.light(ofSize: 14)
   static let light25 = Nunito.light(ofSize: 25)
   static let light36 = Nunito.light(ofSize: 36)

   static let regular9 = Nunito.regular(ofSize: 10)
   static let regular10 = Nunito.regular(ofSize: 10)
   static let regular11 = Nunito.regular(ofSize: 11)
   static let regular12 = Nunito.regular(ofSize: 12)
   static let regular14 = Nunito.regular(ofSize: 14)
   static let regular15 = Nunito.regular(ofSize: 15)
   static let regular16 = Nunito.regular(ofSize: 16)
   static let regular18 = Nunito.regular(ofSize: 18)
   static let regular20 = Nunito.regular(ofSize: 20)
   static let regular34 = Nunito.regular(ofSize: 34)

   static let semiBold10 = Nunito.semiBold(ofSize: 10)
   static let semiBold14 = Nunito.semiBold(ofSize: 14)
   static let semiBold15 = Nunito.semiBold(ofSize: 15)
   static let semiBold16 = Nunito.semiBold(ofSize: 16)
   static let semiBold18 = Nunito.semiBold(ofSize: 18)

   static let extraBold25 = Nunito.extraBold(ofSize: 25)

   static let bold12 = Nunito.bold(ofSize: 12)
   static let bold14 = Nunito.bold(ofSize: 14)
   static let bold18 = Nunito.bold(ofSize: 18)
   static let bold25 = Nunito.bold(ofSize: 25)
}
