//
//  Presentr+Extension.swift
//  App
//
//  Created by Kok Hong Choo on 13/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import Presentr

extension Presentr {
   static let watchlistDetailPresenter: Presentr = {
      let presenter = Presentr(presentationType: .fullScreen)
      presenter.transitionType = .coverVertical
      presenter.dismissTransitionType = .coverVertical
      presenter.backgroundTap = .noAction
      presenter.dismissOnSwipe = true
      presenter.blurBackground = false
      presenter.dismissOnSwipeDirection = .bottom
      return presenter
   }()

   static let createAlertPresenterDark: Presentr = {
      let presenter = Presentr(presentationType: .fullScreen)
      presenter.transitionType = .coverVertical
      presenter.dismissTransitionType = .coverVertical
      presenter.backgroundTap = .noAction
      presenter.dismissOnSwipe = false
      presenter.blurBackground = false
      presenter.backgroundColor = Color.whiteFourteen
      presenter.backgroundOpacity = 0.14
      return presenter
   }()

   static let createAlertPresenterLight: Presentr = {
      let presenter = Presentr(presentationType: .fullScreen)
      presenter.transitionType = .coverVertical
      presenter.dismissTransitionType = .coverVertical
      presenter.backgroundTap = .noAction
      presenter.dismissOnSwipe = false
      presenter.blurBackground = false
      presenter.backgroundColor = Color.blackThirtyThree
      presenter.backgroundOpacity = 0.33
      return presenter
   }()
}
