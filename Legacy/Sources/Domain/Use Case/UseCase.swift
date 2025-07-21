//
//  UseCase.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

open class UseCase<T: Actionable>: UseCaseType {
   public typealias Repository = T
   public typealias Key = T.Key
   public typealias Value = T.Value

   let schedulerExecutor: SchedulerExecutor
   public let repository: Repository

   public init(repository: Repository, schedulerExecutor: SchedulerExecutor) {
      self.repository = repository
      self.schedulerExecutor = schedulerExecutor
   }

   // Must be declared separately rather than as a default parameter above
   // due to a flaw in Xcode 8.2.1.
   // TODO: Remove this workaround for Xcode 8.3+
   public init(repository: Repository) {
      self.repository = repository
      schedulerExecutor = DefaultSchedulerExecutor()
   }

   public func execute<U>(method: @escaping () -> Observable<U>) -> Observable<U> {
      let executor = UseCaseExecutor<T.Key, U>(schedulerExecutor: schedulerExecutor, observableFactory: method)
      func execute<K, U>(executor: UseCaseExecutor<K, U>) -> Observable<U> {
         return Observable<U>
            .create { observer in
               executor.execute(useCaseObserver: observer)
               return Disposables.create()
            }.do(onDispose: {
               executor.stop()
            })
      }
      return execute(executor: executor)
   }
}
