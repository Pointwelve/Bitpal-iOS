//
//  ReloadNavigatorType.swift
//  App
//
//  Created by Ryne Cheow on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

/// Navigator supports reload triggers.
protocol ReloadableNavigatorType: NavigatorType {
   /// Reload if VC is about to become visible.
   var willBecomeVisible: Driver<Bool>! { get set }

   /// Reload if the network becomes reachable, the app is foregrounded,
   /// the VC becomes visible, or the country, gender, or language changes.
   var allTriggers: [ReloadTrigger] { get }

   /// Reload if the network becomes reachable, the app is foregrounded, or the VC becomes visible.
   var defaultTriggers: [ReloadTrigger] { get }

   /// Reload if the country, gender, or language changes.
   var changedSettings: [ReloadTrigger] { get }

   /// Reload if the language has changed.
   var changedLanguage: ReloadTrigger { get }

   /// Reload when we come online.
   var becameReachable: ReloadTrigger { get }

   /// Reload if VC becomes visible.
   var willAppear: ReloadTrigger { get }

   /// Reload if we foreground the app.
   var foregrounded: ReloadTrigger { get }
}

extension ReloadableNavigatorType {
   /// Reload if the network becomes reachable, the app is foregrounded,
   /// the VC becomes visible, or the country, gender, or language changes.
   /// This would be most suited to the Account screen as it views all of this information.
   var allTriggers: [ReloadTrigger] {
      return changedSettings + defaultTriggers
   }

   /// Reload if the network becomes reachable, the app is foregrounded, or the VC becomes visible.
   /// This is the most common triggers that most screens in the app should use. Settings are irrelevant
   /// due to visible trigger forcing a reload anyway.
   var defaultTriggers: [ReloadTrigger] {
      return [becameReachable, willAppear, foregrounded]
   }

   /// Reload if the country, gender, or language changes.
   var changedSettings: [ReloadTrigger] {
      return [changedLanguage]
   }

   /// Reload if the language has changed.
   var changedLanguage: ReloadTrigger {
      return .becameStale(state.preferences.language.skip(1).map { _ in true })
   }

   /// Reload when we come online.
   var becameReachable: ReloadTrigger {
      return .becameReachable(state.preferences.serviceProvider.isOnline
         .asDriver(onErrorJustReturn: false)
         .distinctUntilChanged())
   }

   /// Reload if VC becomes visible.
   var willAppear: ReloadTrigger {
      return .willBecomeVisible(willBecomeVisible.distinctUntilChanged())
   }

   /// Reload if we foreground the app.
   var foregrounded: ReloadTrigger {
      let background = NotificationCenter.default.rx
         .notification(UIApplication.didEnterBackgroundNotification)
         .map { _ in false }
      let foreground = NotificationCenter.default.rx
         .notification(UIApplication.willEnterForegroundNotification)
         .map { _ in true }
      let isForegrounded = Observable
         .merge(background, foreground)
         .asDriver(onErrorJustReturn: true)
         .startWith(true)
      return .inForeground(isForegrounded)
   }
}
