//
//  ValueTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

protocol ValueTransformer {
   associatedtype Input
   associatedtype Output

   func transform(_ input: Input) -> Observable<Output>
}

class ValueTransformerBox<I, O>: ValueTransformer {
   typealias Input = I
   typealias Output = O

   typealias TransformClosure = (I) -> Observable<O>
   private let transformClosure: TransformClosure

   init(_ transformClosure: @escaping TransformClosure) {
      self.transformClosure = transformClosure
   }

   func transform(_ input: I) -> Observable<O> {
      return transformClosure(input)
   }
}
