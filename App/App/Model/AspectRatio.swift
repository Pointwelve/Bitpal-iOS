//
//  AspectRatio.swift
//  App
//
//  Created by Ryne Cheow on 5/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import CoreGraphics

struct AspectRatio {
   let x: CGFloat
   let y: CGFloat

   var widthMultiplier: CGFloat {
      return y / x
   }

   var heightMultiplier: CGFloat {
      return x / y
   }
}
