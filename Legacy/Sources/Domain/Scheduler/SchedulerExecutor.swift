//
//  SchedulerExecutor.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

/// The `SchedulerExecutor` provides two schedulers for background/foreground work.

public protocol SchedulerExecutor {
   /// Get a scheduler for foreground work.
   var foreground: SchedulerType { get }

   /// Get a scheduler for background work.
   var background: SchedulerType { get }
}
