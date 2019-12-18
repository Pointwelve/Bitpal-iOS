//
//  LoadingIndicatorViewModel.swift
//  App
//
//  Created by Li Hao Lai on 29/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

public enum LoadingIndicatorState {
   case loading
   case dismiss(completion: () -> Void)

   var completion: (() -> Void)? {
      switch self {
      case .loading:
         return nil
      case let .dismiss(completionBlock):
         return completionBlock
      }
   }
}

final class LoadingIndicatorViewModel: TransformableViewModelType {
   struct Input {
      let isHidden: Driver<Bool>
      let state: Driver<LoadingIndicatorState>
   }

   struct Output {
      let isHidden: Driver<Bool>
      let state: Driver<LoadingIndicatorState>
   }

   func transform(input: Input) -> Output {
      return .init(isHidden: input.isHidden, state: input.state)
   }
}
