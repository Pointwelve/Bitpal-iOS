//
//  RxObserverType+Void.swift
//  Domain
//
//  Created by Ryne Cheow on 9/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

/// Helper for Subjects to not be forces to invoke onNext with redundant brackets.
/// `subject.onNext()` is more readable than `subject.onNext(())`
extension ObserverType where Element == Void {
   public func onNext() {
      onNext(())
   }
}
