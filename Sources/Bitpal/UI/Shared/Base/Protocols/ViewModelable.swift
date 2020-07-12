//
//  ViewModelable.swift
//  App
//
//  Created by Ryne Cheow on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import UIKit

/// Responsible for presentation and passing user events to `ViewModel` object.
protocol ViewModelable {
   associatedtype ViewModel

   /// `ViewModel` object used for transforming user input into output for presentation.
   var viewModel: ViewModel! { get set }
}

extension ViewModelable where Self: ViewType, Self: UIViewController, Self.ViewModel: ViewModelType {
   /// Entry point for `View` creation.
   ///
   /// - Parameter viewModel: `ViewModel` object used for binding.
   init(viewModel: ViewModel) {
      self.init(nibName: nil, bundle: nil)
      self.viewModel = viewModel
      setup()
   }
}

extension ViewModelable where Self: ViewType, Self: UIViewController, Self.ViewModel: ViewModelType & Navigable {
   init(viewModel: ViewModel) {
      self.init(nibName: nil, bundle: nil)
      self.viewModel = viewModel
      if let reloadable = viewModel.navigator as? ReloadableNavigatorType {
         reloadable.willBecomeVisible = willBecomeVisible
      }
      if let appearable = viewModel.navigator as? AppearableNavigatorType,
         let disposeBagHaving = self as? DisposeBagHaving {
         willBecomeVisible.drive(onNext: appearable.will).disposed(by: disposeBagHaving.disposeBag)
         didBecomeVisible.drive(onNext: appearable.did).disposed(by: disposeBagHaving.disposeBag)
         appearable.didBecomeVisible = didBecomeVisible
      }
      if let parentType = viewModel.navigator as? ParentNavigatorType,
         let disposeBagHaving = self as? DisposeBagHaving {
         willBecomeVisible.drive(onNext: { visible in
            if visible {
               parentType.children.purge()
            }
         }).disposed(by: disposeBagHaving.disposeBag)
      }
      (self as? Layoutable)?.layout()
      (self as? Bindable)?.bind()
   }
}

extension ViewModelable where Self: ViewType, Self: UIView, Self.ViewModel: ViewModelType {
   /// Entry point for `View` creation.
   ///
   /// - Parameter viewModel: `ViewModel` object used for binding.
   init(viewModel: ViewModel) {
      self.init()
      self.viewModel = viewModel
      setup()
   }
}
