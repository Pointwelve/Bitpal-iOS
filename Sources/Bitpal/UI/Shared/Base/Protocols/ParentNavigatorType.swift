//
//  ParentNavigatorType.swift
//  App
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

final class ChildNavigators {
   var navigators: [NavigatorType] = []

   fileprivate func add(_ navigator: NavigatorType) {
      navigators.append(navigator)
   }

   fileprivate func remove(_ navigator: NavigatorType) {
      navigator.cleanup()
      navigators = navigators.filter { $0 !== navigator }
   }

   func purge() {
      navigators.forEach { $0.cleanup() }
      navigators.removeAll()
   }

   func finishAll() {
      navigators.forEach { $0.finish() }
      navigators.removeAll()
   }
}

protocol ParentNavigatorType: NavigatorType {
   /// Internal: Internal object managed by `start(child:)` and `finish(child:)` methods.
   var children: ChildNavigators { get set }

   /// Start navigation to child.
   ///
   /// - Parameter child: `NavigatorType` instance to call `start()` on.
   func start(child: NavigatorType)

   /// Finish navigation from child.
   ///
   /// - Parameter child: `NavigatorType` instance to call `finish()` on.
   func finish(child: NavigatorType)
}

extension ParentNavigatorType {
   func start(child: NavigatorType) {
      children.add(child)
      child.start()
      (child as? Routable)?.handle()
   }

   func finish(child: NavigatorType) {
      child.finish()
      children.remove(child)
   }
}

extension ParentNavigatorType where Self: Appearable {
   func did(appear: Bool) {
      if appear {
         children.purge()
      }
   }
}
