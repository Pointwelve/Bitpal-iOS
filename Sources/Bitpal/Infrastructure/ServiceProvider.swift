//
//  ServiceProvider.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Data
import Domain
import FirebaseAuth
import Foundation
import RxCocoa
import RxSwift

protocol AppServiceProviderType: ServiceProviderType {
   var appState: BehaviorRelay<AppState> { get }
   var routes: BehaviorRelay<RouteDef?> { get }
   var sessionManager: SessionManager { get }
   var repository: AppRepositoryType { get }
   var configuration: Observable<ConfigurationUseCaseCoordinator> { get }
   var isOnline: Driver<Bool> { get }
   var firebaseAuthProvider: FirebaseAuthProvider { get }
}

struct ServiceProvider: AppServiceProviderType {
   let appState: BehaviorRelay<AppState> = BehaviorRelay(value: .authenticating)
   let routes: BehaviorRelay<RouteDef?> = BehaviorRelay(value: nil)

   static let shared: ServiceProvider = {
      let memoryWarning = NotificationCenter.default.rx
         .notification(UIApplication.didReceiveMemoryWarningNotification)
         .map { _ in Void() }
      let appEnteredBackground = NotificationCenter.default.rx
         .notification(UIApplication.didEnterBackgroundNotification)
         .void()
      let appEnteredForeground = NotificationCenter.default.rx
         .notification(UIApplication.willEnterForegroundNotification)
         .void()
      let appWillTerminate = NotificationCenter.default.rx
         .notification(UIApplication.willTerminateNotification)
         .void()
      let firebaseAuthProvider = FirebaseAuthProvider()

      let sessionManager = SessionManager(bundle: .main,
                                          getPreferredLanguage: { Language.preferred ?? .default },
                                          getPreferredTheme: { Theme.preferred ?? .default },
                                          getPreferredChartType: { ChartType.preferred ?? .line },
                                          getFirebaseAuth: firebaseAuthProvider,
                                          memoryWarning: memoryWarning,
                                          appEnteredBackground: appEnteredBackground,
                                          appEnteredForeground: appEnteredForeground,
                                          appWillTerminate: appWillTerminate)
      return .init(sessionManager: sessionManager, firebaseAuthProvider: firebaseAuthProvider)
   }()

   let sessionManager: SessionManager
   let firebaseAuthProvider: FirebaseAuthProvider
   let isOnline: Driver<Bool>

   var repository: AppRepositoryType {
      return sessionManager.repository
   }

   var configuration: Observable<ConfigurationUseCaseCoordinator> {
      return sessionManager.configuration
   }

   init(sessionManager: SessionManager, firebaseAuthProvider: FirebaseAuthProvider) {
      self.firebaseAuthProvider = firebaseAuthProvider
      self.sessionManager = sessionManager
      isOnline = sessionManager.repository.device.isOnline().getResult()
         .map { $0.contentValue?.isOnline ?? false }
         .asDriver(onErrorJustReturn: false)
         .distinctUntilChanged()
   }
}

// MARK: - Helper

extension Language {
   /// Get the localization the app is currently launched in from the Bundle.
   static var preferred: Language? {
      return Language(rawValue: Locale.current.languageCode ?? "en")
   }
}

extension Theme {
   static var preferred: Theme? {
      let themeName = UserDefaults.standard.string(forKey: Theme.identifier) ?? ""
      return Theme(name: themeName)
   }
}

extension ChartType {
   static var preferred: ChartType? {
      return .line
   }
}
