//
//  BidirectionalValueTransformer.swift
//  Data
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation
import RxSwift

protocol BirectionalValueTransformer: ValueTransformer {
   func transform(_ input: Output) -> Observable<Input>
}

class BidirectionalValueTransformerBox<I, O>: BirectionalValueTransformer {
   typealias Input = I
   typealias Output = O

   typealias TransformClosure = (I) -> Observable<O>
   typealias InverseClosure = (O) -> Observable<I>

   private let transformClosure: TransformClosure
   private let inverseClosure: InverseClosure

   init(_ transformClosure: @escaping TransformClosure,
        _ inverseClosure: @escaping InverseClosure) {
      self.transformClosure = transformClosure
      self.inverseClosure = inverseClosure
   }

   func transform(_ input: I) -> Observable<O> {
      return transformClosure(input)
   }

   func transform(_ input: O) -> Observable<I> {
      return inverseClosure(input)
   }
}
