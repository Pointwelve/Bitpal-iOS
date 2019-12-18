//
//  RootViewController.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

final class RootViewController: BaseTabBarController, DefaultViewControllerType {
   enum Metric {}

   typealias ViewModel = RootViewModel

   var disposeBag = DisposeBag()
   var viewModel: RootViewModel!

   func layout() {}

   func bind() {
      _ = viewModel.transform(input: ())
   }
}
