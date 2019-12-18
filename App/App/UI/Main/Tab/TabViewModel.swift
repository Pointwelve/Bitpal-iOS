//
//  TabViewModel.swift
//  App
//
//  Created by Ryne Cheow on 21/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

/// Responsible for setting the localized title of the tab.
final class TabViewModel: ViewModelType {
   weak var navigator: NavigatorType!

   init(navigator: NavigatorType) {
      self.navigator = navigator
   }

   struct Input {
      let tabType: TabType
   }

   struct Output {
      let tabTitle: Driver<String>
   }

   func transform(input: Input) -> Output {
      return Output(tabTitle: navigator.state.preferences.language.map { _ in input.tabType.tabName })
   }
}
