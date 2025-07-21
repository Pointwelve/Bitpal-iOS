//
//  SettingsNavigator.swift
//  App
//
//  Created by Kok Hong Choo on 20/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

protocol SettingsNavigatorType: TabRootNavigatorType, ParentNavigatorType {
   func showTermsAndCondition()
   func showCredits()
}

/// Responsible for presenting tab view controller for main screen.

final class SettingsNavigator: SettingsNavigatorType {
   var tabType: TabType!
   private let disposeBag = DisposeBag()
   var children = ChildNavigators()
   var state: NavigationState!

   func start() {
      let viewModel = SettingsViewModel(navigator: self)
      let viewController = SettingsViewController(viewModel: viewModel)
      state.navigationController?.pushViewController(viewController, animated: true)
      if #available(iOS 11.0, *) {
         state.navigationController?.navigationBar.prefersLargeTitles = true
      }
   }

   func finish() {}

   func showTermsAndCondition() {
      let navigator = TermsAndConditionsNavigator(state: .init(parent: self))
      start(child: navigator)
   }

   func showCredits() {
      let navigator = CreditsNavigator(state: .init(parent: self))
      start(child: navigator)
   }
}

extension SettingsNavigator: Routable {
   func handle() {
      let routes = state.preferences.serviceProvider.routes

      routes.asDriver()
         .startWith(routes.value)
         .filterNil()
         .drive(onNext: { [weak self] routeDef in
            guard let `self` = self else {
               return
            }

            switch routeDef.route {
            case .termsAndConditions:
               guard self.children.navigators.last is TermsAndConditionsNavigator else {
                  self.showTermsAndCondition()
                  break
               }

            default:
               break
            }
         })
         .disposed(by: disposeBag)
   }
}
