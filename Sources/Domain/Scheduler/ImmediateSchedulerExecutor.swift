//
//  ImmediateSchedulerExecutor.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

public final class ImmediateSchedulerExecutor: SchedulerExecutor {
   public let foreground: SchedulerType
   public let background: SchedulerType

   public init() {
      foreground = ConcurrentMainScheduler.instance
      background = foreground
   }
}
