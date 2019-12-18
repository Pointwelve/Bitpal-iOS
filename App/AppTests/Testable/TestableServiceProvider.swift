//
//  TestableServiceProvider.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import Data
import Domain
import FirebaseAuth
import Foundation
import RxCocoa
import RxSwift
import XCTest

class TestableServiceProvider: AppServiceProviderType {
   var routes: BehaviorRelay<RouteDef?>

   var appState: BehaviorRelay<AppState>

   var firebaseAuthProvider: FirebaseAuthProvider

   var sessionManager: SessionManager {
      let sessionManager = SessionManager(bundle: .main,
                                          getPreferredLanguage: { .default },
                                          getPreferredTheme: { .default },
                                          getPreferredChartType: { .line },
                                          getFirebaseAuth: TestableFirebaseAuthProvider(),
                                          memoryWarning: .empty(),
                                          appEnteredBackground: .empty(),
                                          appEnteredForeground: .empty(),
                                          appWillTerminate: .empty())
      return sessionManager
   }

   var location: LocationProviderType {
      return TestableLocationProvider()
   }

   var repository: AppRepositoryType

   var configuration: Observable<ConfigurationUseCaseCoordinator> {
      return sessionManager.configuration
   }

   required init(repository: AppRepositoryType) {
      self.repository = repository
      firebaseAuthProvider = FirebaseAuthProvider()
      appState = BehaviorRelay<AppState>(value: .authenticated)
      routes = BehaviorRelay<RouteDef?>(value: nil)
   }

   var isOnline: Driver<Bool> {
      return Driver.just(true)
   }

   var currentUser: Observable<User> {
      return Observable.empty()
   }
}
