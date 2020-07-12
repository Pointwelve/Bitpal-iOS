//
//  UIApplication+Extensions.swift
//  App
//
//  Created by James Lai on 16/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit
import UserNotifications

extension UIApplication {
   func isEnabledForRemoteNotifications() -> Driver<Bool> {
      return Observable.deferred {
         Observable.create { observer in
            UNUserNotificationCenter.current()
               .requestAuthorization(options: [.alert], completionHandler: { granted, error in
                  if let error = error {
                     observer.on(.error(error))
                     return
                  }

                  observer.on(.next(granted))
                  return
               })

            return Disposables.create()
         }
      }.asDriver(onErrorJustReturn: false)
   }
}
