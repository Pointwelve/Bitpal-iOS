//
//  UseCaseExecutor.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

class UseCaseExecutor<K, V>: UseCaseExecutorType {
   typealias Key = K
   typealias Value = V

   private let schedulerExecutor: SchedulerExecutor
   private var disposable: Disposable?
   private let observableFactory: () -> (Observable<V>)

   required init(schedulerExecutor: SchedulerExecutor, observableFactory: @escaping () -> Observable<V>) {
      self.observableFactory = observableFactory
      self.schedulerExecutor = schedulerExecutor
   }

   var isRunning: Bool {
      return disposable != nil
   }

   func execute(useCaseObserver: AnyObserver<Value>) {
      // stops the previous executing if it has been executing already
      stop()

      // Defer observable creation until we have subscribed to avoid observable
      // being created on the main thread.
      let observable = Observable.deferred {
         self.observableFactory()
      }
      .subscribeOn(schedulerExecutor.background)
      .observeOn(schedulerExecutor.foreground)

      // Create disposable
      disposable = observable.subscribe(useCaseObserver)
   }

   func stop() {
      guard isRunning else {
         return
      }
      disposable?.dispose()
      disposable = nil
   }
}
