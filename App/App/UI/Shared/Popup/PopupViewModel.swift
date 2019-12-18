//
//  PopupViewModel.swift
//  App
//
//  Created by Li Hao Lai on 24/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class PopupViewModel: TransformableViewModelType {
   struct Input {
      var defaultButtonAction: Driver<Void>
      var cancelButtonAction: Driver<Void>
   }

   struct Output {
      var didSelectedAction: Driver<Bool>
   }

   func transform(input: Input) -> Output {
      let didSelectedAction = Driver.merge([input.defaultButtonAction, input.cancelButtonAction])
         .map { true }

      return .init(didSelectedAction: didSelectedAction)
   }
}
