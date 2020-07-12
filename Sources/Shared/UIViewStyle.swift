//
//  UIViewStyle.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//
//  Discussed here:
//  https://medium.cobeisfresh.com/composable-type-safe-uiview-styling-with-swift-functions-8be417da947f#.g771n4ctz

import UIKit

/// An abstraction of `UIView` styling.

struct UIViewStyle<T> {
   /// The styling function that takes a `UIView` instance and performs side-effects on it.
   let styling: (T) -> Void

   /// A factory method that composes multiple styles.
   ///
   /// - Parameter styles: The styles to compose.
   /// - Returns: A new `UIViewStyle` that will call the input styles'
   ///            `styling` method in succession.
   static func compose(_ styles: UIViewStyle<T>...) -> UIViewStyle<T> {
      return UIViewStyle { view in
         styles.forEach {
            $0.styling(view)
         }
      }
   }

   /// Compose this style with another.
   ///
   /// - Parameter other: Other style to compose this style with.
   /// - Returns: A new `UIViewStyle` which will call this style's `styling`,
   ///            and then the `other` style's `styling`.
   func composing(with other: UIViewStyle<T>) -> UIViewStyle<T> {
      return UIViewStyle { view in
         self.styling(view)
         other.styling(view)
      }
   }

   /// Compose this style with another styling function.
   ///
   /// - Parameter otherStyling: The function to compose this style with.
   /// - Returns: A new `UIViewStyle` which will call this style's `styling`,
   ///            and then the input `styling`.
   func composing(with otherStyling: @escaping (T) -> Void) -> UIViewStyle<T> {
      return composing(with: UIViewStyle(styling: otherStyling))
   }

   /// Apply this style to a UIView.
   ///
   /// - Parameter view: the view to style
   func apply(to view: T) {
      styling(view)
   }

   /// Apply this style to multiple views.
   ///
   /// - Parameter views: the views to style
   func apply(to views: T...) {
      for view in views {
         styling(view)
      }
   }
}
