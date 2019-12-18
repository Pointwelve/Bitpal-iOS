//
//  TabNavigationController.swift
//  App
//
//  Created by Ryne Cheow on 21/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

extension Reactive where Base: UITabBarItem {
   /// Reactive wrapper for `title`
   public var title: Binder<String?> {
      return Binder<String?>(base) { tabBarItem, title in
         tabBarItem.title = title
      }
   }
}

/// Responsible for configuring the tab title and icon.
final class TabNavigationController: BaseNavigationController, ViewType {
   typealias ViewModel = TabViewModel
   var viewModel: ViewModel!
   var disposeBag: DisposeBag! = DisposeBag()
   private var tabType: TabType!

   init(viewModel: ViewModel, tabType: TabType) {
      super.init(nibName: nil, bundle: nil)
      self.viewModel = viewModel
      self.tabType = tabType
      layout()
      bind()
   }

   required init(viewModel: ViewModel) {
      fatalError("init(viewModel:) has not been implemented")
   }

   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }

   func bind() {
      let output = viewModel.transform(input: .init(tabType: tabType))
      output.tabTitle
         .drive(tabBarItem.rx.title)
         .disposed(by: disposeBag)
   }

   func layout() {
      Style.TabBar.itemImage(tabType.tabIcon).apply(to: tabBarItem)
      tabBarItem.setAccessibility(id: tabType.tabAccessibilityId)
   }
}
