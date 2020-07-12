//
//  Rx+If.swift
//  App
//
//  Created by Ryne Cheow on 22/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension ObservableType where Element == Bool {
   public func ifTrue() -> Observable<Bool> {
      return filter { $0 }
   }

   public func ifFalse() -> Observable<Bool> {
      return filter { !$0 }
   }
}

extension SharedSequenceConvertibleType where Element == Bool {
   public func ifTrue() -> SharedSequence<SharingStrategy, Bool> {
      return filter { $0 }
   }

   public func ifFalse() -> SharedSequence<SharingStrategy, Bool> {
      return filter { !$0 }
   }
}
