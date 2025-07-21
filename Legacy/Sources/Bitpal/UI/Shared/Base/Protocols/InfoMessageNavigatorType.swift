//
//  InfoMessageNavigatorType.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

protocol InfoMessageNavigatorType: PopupPresenterNavigatorType {
   func showInfo(title: String, message: String)
   func infoDismissed()
}

extension InfoMessageNavigatorType {
   func showInfo(title: String, message: String) {
      presentPopup(title: title, message: message, onClose: infoDismissed)
   }
}
