//
//  Rx+Void.swift
//  App
//
//  Created by Ryne Cheow on 13/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension ObservableType {
   /// Discard value returning void instead
   public func void() -> Observable<Void> {
      return map { _ in () }
   }
}

extension SharedSequenceConvertibleType {
   /// Discard value returning void instead
   public func void() -> SharedSequence<SharingStrategy, Void> {
      return map { _ in () }
   }
}
