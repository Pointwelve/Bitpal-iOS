//
//  BaseTabBarController.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class BaseTabBarController: UITabBarController {
   var baseDisposeBag: DisposeBag!

   override func viewDidLoad() {
      super.viewDidLoad()
      tabBar.setAccessibility(id: .tabBar)
      baseDisposeBag = DisposeBag()

      ThemeProvider.current
         .drive(onNext: { theme in
            theme.tabBar.apply(to: self.tabBar)
         })
         .disposed(by: baseDisposeBag)
   }
}
