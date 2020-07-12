//
//  Rx+Optional.swift
//  App
//
//  Created by Ryne Cheow on 14/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension ObservableType {
   /// Convert observable to optional.
   public func asOptional() -> Observable<Element?> {
      return map { .some($0) }
   }

   public func asTypeErasedDriver() -> Driver<Void> {
      return asOptional()
         .asDriver(onErrorJustReturn: nil)
         .filterNil()
         .void()
   }
}

extension SharedSequenceConvertibleType {
   /// Convert sequence to optional.
   public func asOptional() -> SharedSequence<SharingStrategy, Element?> {
      return map { .some($0) }
   }
}
