//
//  AppNavigator.swift
//  App
//
//  Created by Ryne Cheow on 25/3/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import CloudKit
import FirebaseCrashlytics
import Domain
import Firebase
import FirebaseAuth
import Foundation
import RxCocoa
import RxSwift
import UIKit
// import SwiftKeychainWrapper

/// Responsible for managing window root view controller.

final class AppNavigator: ParentNavigatorType {
   let disposeBag = DisposeBag()
   var children = ChildNavigators()
   var state: NavigationState!

   var pushToken = BehaviorRelay<String?>(value: nil)

   private func presentBase(with currentState: AppState) {
      let window = state.window!
      children.purge()

      switch currentState {
      case .authenticating:
         let mainState = NavigationState(parent: self, preferences: state.preferences)
         let navigator = SplashNavigator(state: mainState)
         let splashViewModel = SplashViewModel(navigator: navigator)
         let splashController = SplashViewController(viewModel: splashViewModel)
         start(child: navigator)

         window.rootViewController = splashController
      case .authenticated:
         // Onboarded, show main tabs
         let tabBarController = BaseTabBarController()
         let mainState = NavigationState(parent: self,
                                         tabBarController: tabBarController,
                                         preferences: state.preferences)
         let mainNavigator = MainNavigator(state: mainState)
         start(child: mainNavigator)

//         UIView.transition(with: window, duration: 0.5,
//                           options: .transitionCrossDissolve, animations: {
         window.rootViewController = tabBarController
//         })
      }
   }

   func start() {
      state.window?.makeKeyAndVisible()

      state.preferences.serviceProvider.appState
         .asDriver()
         .drive(onNext: { [weak self] currentState in
            guard let `self` = self else {
               return
            }
            self.presentBase(with: currentState)
         })
         .disposed(by: disposeBag)

      let authenticatedStatus = state.preferences.serviceProvider.appState
         .asDriver().filter { $0 == .authenticated }

      Driver.combineLatest(authenticatedStatus, pushToken.asDriver().skip(1).filterNil()) { $1 }
         .drive(onNext: { [weak self] token in
            guard let `self` = self else {
               return
            }
            self.register(pushNotificationToken: token)
         })
         .disposed(by: disposeBag)

      // need to load first theme for all state
      state.preferences.theme
         .drive()
         .disposed(by: disposeBag)
   }

   func finish() {
      // Do nothing
   }

   func register(pushNotificationToken token: String) {
      state.preferences.serviceProvider.repository.pushNotification.register(token: token)
         .getResult()
         .asDriver(onErrorJustReturn: .failure(.error(UseCaseError.executionFailed)))
         .drive()
         .disposed(by: disposeBag)
   }
}
