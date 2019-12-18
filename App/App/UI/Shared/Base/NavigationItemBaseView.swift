//
//  NavigationItemBaseView.swift
//  App
//
//  Created by Kok Hong Choo on 7/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

final class NavigationItemBaseView: UIView {
   override var intrinsicContentSize: CGSize {
      return UIView.layoutFittingExpandedSize
   }
}

final class NavigationItemBaseTextField: UITextField {
   override var intrinsicContentSize: CGSize {
      return UIView.layoutFittingExpandedSize
   }
}
