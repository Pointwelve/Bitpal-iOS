//
//  IOBindable.swift
//  App
//
//  Created by Ryne Cheow on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

/// Useful when binding a class that has not been provided inputs and may return outputs.
protocol IOBindable {
   associatedtype Input
   associatedtype Output
   func bind(input: Input) -> Output
}
