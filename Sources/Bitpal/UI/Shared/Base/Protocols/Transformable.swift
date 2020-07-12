//
//  Transformable.swift
//  App
//
//  Created by Ryne Cheow on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

/// Responsible for transforming input into output.
protocol Transformable {
   associatedtype Input
   associatedtype Output

   /// Transforms `Input` into `Output`.
   ///
   /// - Parameter input: Data to transform.
   /// - Returns: Transformed data.
   func transform(input: Input) -> Output
}
