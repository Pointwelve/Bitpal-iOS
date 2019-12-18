//
//  Rx+Not.swift
//  App
//
//  Created by Ryne Cheow on 13/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension ObservableType where Element == Bool {
   /// Boolean not operator
   public func not() -> Observable<Bool> {
      return map(!)
   }
}

extension SharedSequenceConvertibleType where Element == Bool {
   /// Boolean not operator.
   public func not() -> SharedSequence<SharingStrategy, Bool> {
      return map(!)
   }
}
