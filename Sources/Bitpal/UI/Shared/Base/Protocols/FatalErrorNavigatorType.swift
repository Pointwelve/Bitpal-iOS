//
//  FatalErrorNavigatorType.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxCocoa
import RxSwift
import UIKit

protocol FatalErrorNavigatorType: PopupPresenterNavigatorType {
   func showError(_ error: Error, onClose: (() -> Void)?)
   func errorDismissed()
   func showError(title: String, message: String, onClose: (() -> Void)?)
}

extension FatalErrorNavigatorType {
   func showError(_ error: Error) {
      showError(error, onClose: nil)
   }

   func showError(_ error: Error, onClose: (() -> Void)?) {
      switch error {
      case CacheError.expired:
         presentPopup(title: "error.sorry.title".localized(),
                      message: "error.sorry.message".localized(),
                      onClose: onClose ?? {})
      default:
         // Suppress error and use standard copy
         presentPopup(title: "error.sorry.title".localized(),
                      message: "error.sorry.message".localized(),
                      onClose: onClose ?? errorDismissed)
      }
   }

   func showError(title: String, message: String, onClose: (() -> Void)?) {
      presentPopup(title: title,
                   message: message,
                   onClose: onClose ?? errorDismissed)
   }
}
