//
//  CreditsViewModel.swift
//  App
//
//  Created by James Lai on 8/11/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class CreditsViewModel: TransformableViewModelType, Navigable {
   typealias Input = Void

   struct Output {
      let content: Driver<NSMutableAttributedString>
   }

   var navigator: CreditsNavigatorType!

   init(navigator: CreditsNavigatorType) {
      self.navigator = navigator
   }

   func transform(input: Void) -> Output {
      let content = NSMutableAttributedString(string: "credits.content".localized())
      let ccRange = content.mutableString.range(of: "cryptoCompare".localized())
      let ccUrl = URL(string: "https://www.cryptocompare.com")!

      content.addAttribute(.link, value: ccUrl, range: ccRange)
      content.endEditing()

      return .init(content: .just(content))
   }
}
