//
//  TermsAndConditionsViewModel.swift
//  App
//
//  Created by James Lai on 27/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

final class TermsAndConditionsViewModel: TransformableViewModelType, Navigable {
   weak var navigator: TermsAndConditionsNavigator!

   init(navigator: TermsAndConditionsNavigator) {
      self.navigator = navigator
   }

   typealias Input = Void

   struct Output {
      let companyTitleDriver: Driver<String>
      let termsAndConditionsDriver: Driver<String>
   }

   func transform(input: Void) -> Output {
      let dataDriver = navigator.state.preferences
         .serviceProvider.configuration

      let companyTitleDriver = dataDriver.map { $0.companyName }
         .asDriver(onErrorJustReturn: "")

      let termsAndConditionsDriver = dataDriver.map { $0.termsAndConditions }
         .asDriver(onErrorJustReturn: "")

      return .init(companyTitleDriver: companyTitleDriver,
                   termsAndConditionsDriver: termsAndConditionsDriver)
   }
}
