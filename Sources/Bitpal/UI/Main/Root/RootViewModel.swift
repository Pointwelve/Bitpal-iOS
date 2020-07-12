//
//  RootViewModel.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift

final class RootViewModel: TransformableViewModelType, Navigable {
   weak var navigator: RootNavigatorType!

   init(navigator: RootNavigatorType) {
      self.navigator = navigator
   }

   typealias Input = Void

   typealias Output = Void

   func transform(input: Input) -> Output {}
}
