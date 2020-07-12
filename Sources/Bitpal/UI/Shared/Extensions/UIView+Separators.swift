//
//  UIView+Separators.swift
//  App
//
//  Created by Ryne Cheow on 13/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
   // Defining the border view tag
   fileprivate static let borderViewTag = 990_001

   static func makeLineView(color: UIColor = .black,
                            tag: Int? = nil) -> UIView {
      let line = UIView(frame: .zero)
      line.backgroundColor = color
      line.translatesAutoresizingMaskIntoConstraints = false
      if let tag = tag {
         line.tag = tag
      }
      return line
   }

   @discardableResult
   func addBorder(edges: UIRectEdge,
                  color: UIColor = .black,
                  thickness: CGFloat = 1.0 / UIScreen.main.scale) -> [UIView] {
      var borders = [UIView]()

      // Remove all existing borders before adding to prevent dupes of lines
      subviews.filter {
         $0.tag == UIView.borderViewTag
      }.forEach {
         $0.removeFromSuperview()
      }

      func border() -> UIView {
         return UIView.makeLineView(color: color, tag: UIView.borderViewTag)
      }

      if edges.contains(.top) || edges.contains(.all) {
         let top = border()
         addSubview(top)
         NSLayoutConstraint.activate([
            top.heightAnchor.constraint(equalToConstant: thickness),
            top.topAnchor.constraint(equalTo: topAnchor),
            top.leadingAnchor.constraint(equalTo: leadingAnchor),
            top.trailingAnchor.constraint(equalTo: trailingAnchor)
         ])
         borders.append(top)
      }

      if edges.contains(.left) || edges.contains(.all) {
         let left = border()
         addSubview(left)
         NSLayoutConstraint.activate([
            left.widthAnchor.constraint(equalToConstant: thickness),
            left.leftAnchor.constraint(equalTo: leftAnchor),
            left.topAnchor.constraint(equalTo: topAnchor),
            left.bottomAnchor.constraint(equalTo: bottomAnchor)
         ])
         borders.append(left)
      }

      if edges.contains(.right) || edges.contains(.all) {
         let right = border()
         addSubview(right)
         NSLayoutConstraint.activate([
            right.widthAnchor.constraint(equalToConstant: thickness),
            right.rightAnchor.constraint(equalTo: rightAnchor),
            right.topAnchor.constraint(equalTo: topAnchor),
            right.bottomAnchor.constraint(equalTo: bottomAnchor)
         ])
         borders.append(right)
      }

      if edges.contains(.bottom) || edges.contains(.all) {
         let bottom = border()
         addSubview(bottom)
         NSLayoutConstraint.activate([
            bottom.heightAnchor.constraint(equalToConstant: thickness),
            bottom.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottom.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottom.trailingAnchor.constraint(equalTo: trailingAnchor)
         ])
         borders.append(bottom)
      }

      return borders
   }
}
