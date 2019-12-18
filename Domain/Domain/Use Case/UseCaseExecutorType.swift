//
//  UseCaseExecutorType.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

protocol UseCaseExecutorType: class {
   /// The key used for looking up the value
   associatedtype Key
   /// The value returned by this use case
   associatedtype Value

   // init(schedulerExecutor: SchedulerExecutor, observableFactory: @escaping () -> Observable<Value>)

   /// Defines whether this use case is performed.
   /// - returns: `true` if it is performed, `false` otherwise
   var isRunning: Bool { get }

   /// Executes the current use case.
   /// Note: it stops the previous executing if it has been executing already,
   /// so you can check if it is running by checking `isRunning`.
   ///
   /// - Parameter useCaseObserver: `AnyObserver` which will be listening to the observable.
   func execute(useCaseObserver: AnyObserver<Value>)

   /// Stops this use case.
   func stop()
}
