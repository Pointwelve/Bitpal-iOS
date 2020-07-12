//
//  DefaultSchedulerExecutor.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public final class DefaultSchedulerExecutor: SchedulerExecutor {
   public let foreground: SchedulerType
   public let background: SchedulerType

   public init(background: SchedulerType = ConcurrentDispatchQueueScheduler(queue: .global(qos: .background)),
               foreground: SchedulerType = ConcurrentMainScheduler.instance) {
      self.foreground = foreground
      self.background = background
   }
}
