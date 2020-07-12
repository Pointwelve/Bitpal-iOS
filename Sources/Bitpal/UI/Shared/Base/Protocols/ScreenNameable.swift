//
//  ScreenNameable.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

/// View controllers should implement this protocol if they have a text title.

protocol ScreenNameable {
   /// Accessibility identifier for title label.
   var screenNameAccessibilityId: AccessibilityIdentifier { get }

   /// Replace title with custom label with given title.
   func update(screenName: String)

   /// Replace title with custom label with given attributed.
   func update(attributedScreenName: NSAttributedString, navigationItem: UINavigationItem)
}

extension ScreenNameable where Self: UIViewController {
   func update(screenName: String) {
      navigationItem.title = screenName
      navigationItem.titleView?.setAccessibility(id: screenNameAccessibilityId)
   }

   private func makeNavigationTitleLabel(withAtttibutedTitle attributedTitle: NSAttributedString) -> UILabel {
      let titleLabel = UILabel()
      titleLabel.numberOfLines = 0
      titleLabel.attributedText = attributedTitle
      titleLabel.sizeToFit()
      if let bounds = navigationController?.navigationBar.bounds {
         titleLabel.center = CGPoint(x: bounds.midX, y: bounds.midY)
      }
      return titleLabel
   }

   func update(attributedScreenName: NSAttributedString, navigationItem: UINavigationItem) {
      navigationItem.titleView = makeNavigationTitleLabel(withAtttibutedTitle: attributedScreenName)
      navigationItem.titleView?.setAccessibility(id: screenNameAccessibilityId)
   }
}
