//
//  BaseNavigationController.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

/// All navigation controllers should inherit from this class.

class BaseNavigationController: UINavigationController {
   var baseDisposeBag: DisposeBag!

   override func viewDidLoad() {
      super.viewDidLoad()

      baseDisposeBag = DisposeBag()

      ThemeProvider.current
         .drive(onNext: { theme in
            theme.navigationBar.apply(to: self.navigationBar)
            theme.view.apply(to: self.view)
         })
         .disposed(by: baseDisposeBag)
   }

   override func pushViewController(_ viewController: UIViewController, animated: Bool) {
      viewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "",
                                                                        style: .plain,
                                                                        target: nil,
                                                                        action: nil)
      super.pushViewController(viewController, animated: true)
   }
}
