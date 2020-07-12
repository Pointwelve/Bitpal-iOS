//
//  ReloadTrigger.swift
//  App
//
//  Created by Ryne Cheow on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

protocol ReloadTriggerType {
   var reachabilityTrigger: Driver<Bool>? { get }
   var foregroundTrigger: Driver<Bool>? { get }
   var visibleTrigger: Driver<Bool>? { get }
   var value: Driver<Bool> { get }
}

enum ReloadTrigger: ReloadTriggerType {
   /// Reload if VM/VC tells us it's state is stale.
   case becameStale(Driver<Bool>)
   /// Reload only if VC becomes visible (must be included).
   case willBecomeVisible(Driver<Bool>)
   /// Reload only if Network is reachable (must be included).
   case becameReachable(Driver<Bool>)
   /// Reload only if the app is in the foreground.
   case inForeground(Driver<Bool>)

   var foregroundTrigger: Driver<Bool>? {
      switch self {
      case let .inForeground(value): return value
      default: return nil
      }
   }

   var visibleTrigger: Driver<Bool>? {
      switch self {
      case let .willBecomeVisible(value): return value
      default: return nil
      }
   }

   var reachabilityTrigger: Driver<Bool>? {
      switch self {
      case let .becameReachable(value): return value
      default: return nil
      }
   }

   var value: Driver<Bool> {
      switch self {
      case let .becameStale(value): return value
      case let .willBecomeVisible(value): return value
      case let .becameReachable(value): return value
      case let .inForeground(value): return value
      }
   }
}

extension Array where Element: ReloadTriggerType {
   var reloadTrigger: Driver<Void> {
      guard let visibleTrigger = compactMap({ $0.visibleTrigger }).first,
         let reachabilityTrigger = compactMap({ $0.reachabilityTrigger }).first,
         let foregroundTrigger = compactMap({ $0.foregroundTrigger }).first else {
         fatalError("Missing a required trigger")
      }
      let shouldReload = Driver.merge(compactMap { $0.value })
      let reloadTrigger = Driver
         // Only reload if VC is visible, the app is foregrounded, and should reload is true.
         // Also trigger reload when reachability changes.
         .combineLatest(visibleTrigger, foregroundTrigger, reachabilityTrigger, shouldReload) { $0 && $1 && $3 }
         .ifTrue()
         .void()
         // Multiple of these may be true in quick succession, lets filter the ones
         // that are too close together.
         .debounce(.milliseconds(10))

      return reloadTrigger
   }
}
