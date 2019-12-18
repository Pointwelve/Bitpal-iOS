//
//  UIImage+Extensions.swift
//  App
//
//  Created by Ryne Cheow on 6/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

extension UIImage {
   func tint(with color: UIColor) -> UIImage {
      UIGraphicsBeginImageContext(size)
      guard let context = UIGraphicsGetCurrentContext() else { return self }

      // flip the image
      context.scaleBy(x: 1.0, y: -1.0)
      context.translateBy(x: 0.0, y: -size.height)

      // multiply blend mode
      context.setBlendMode(.multiply)

      let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
      context.clip(to: rect, mask: cgImage!)
      color.setFill()
      context.fill(rect)

      // create UIImage
      guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }
      UIGraphicsEndImageContext()

      return newImage
   }
}
