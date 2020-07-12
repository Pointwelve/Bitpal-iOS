//
//  WidgetServiceProvider.swift
//  App
//
//  Created by Li Hao Lai on 30/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Data
import Domain
import Foundation
import RxCocoa
import RxSwift

protocol WidgetServiceProviderType: ServiceProviderType {
   var sessionManager: WidgetSessionManager { get }
   var repository: WidgetRepositoryType { get }
}

struct WidgetServiceProvider: WidgetServiceProviderType {
   let sessionManager: WidgetSessionManager
   let isOnline: Driver<Bool>

   var repository: WidgetRepositoryType {
      return sessionManager.repository
   }

   var configuration: Observable<ConfigurationUseCaseCoordinator> {
      return sessionManager.configuration
   }

   static let shared: WidgetServiceProvider = {
      let memoryWarning = NotificationCenter.default.rx
         .notification(UIApplication.didReceiveMemoryWarningNotification)
         .map { _ in Void() }
      let sessionManager = WidgetSessionManager(bundle: .main, memoryWarning: memoryWarning)

      return .init(sessionManager: sessionManager)
   }()

   init(sessionManager: WidgetSessionManager) {
      self.sessionManager = sessionManager
      isOnline = sessionManager.repository.device.isOnline().getResult()
         .map { $0.contentValue?.isOnline ?? false }
         .asDriver(onErrorJustReturn: false)
         .distinctUntilChanged()
   }
}
