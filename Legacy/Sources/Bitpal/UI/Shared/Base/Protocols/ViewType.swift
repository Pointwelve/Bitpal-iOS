//
//  ViewType.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxSwift
import UIKit

typealias DefaultViewControllerType = ViewType & ViewModelable & Bindable & Layoutable & DisposeBagHaving

typealias BaseViewType = ViewType & Layoutable & DisposeBagHaving

typealias ViewModelableViewType = BaseViewType & ViewModelable

typealias IOBindableViewType = BaseViewType & IOBindable

protocol ViewType: class {
   func setup()
}

extension ViewType {
   func setup() {
      (self as? Layoutable)?.layout()
      (self as? Bindable)?.bind()
   }
}

extension ViewType where Self: UIView {
   init(shouldSetup: Bool) {
      self.init(frame: .zero)
      if shouldSetup {
         setup()
      }
   }
}
