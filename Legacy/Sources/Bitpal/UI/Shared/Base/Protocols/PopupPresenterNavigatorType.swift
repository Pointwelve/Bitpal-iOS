//
//  PopupPresenterType.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

protocol PopupPresenterNavigatorType: NavigatorType {}

extension PopupPresenterNavigatorType {
   func presentPopup(title: String,
                     message: String,
                     buttonTitle: String = "button.ok".localized(),
                     onClose: @escaping () -> Void) {
      // Suppress error and use standard copy
      // Note: It's OK to not use a Driver here for language because it is highly unlikely a user would
      // be able to change their language while they are showing an alert.
      let alertController = UIAlertController(title: title,
                                              message: message, preferredStyle: .alert)
      alertController.addAction(.init(title: buttonTitle, style: .cancel))
      controller?.present(alertController, animated: true, completion: { [weak self] in
         self?.dismissPopup(completion: onClose)
      })
   }

   private func dismissPopup(completion: @escaping () -> Void) {
      // Delay until presented view controller is nil
      if controller?.presentedViewController != nil {
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.dismissPopup(completion: completion)
         }
         return
      }
      // Call error dismissed, navigator should implement the action to take
      completion()
   }
}
