//
//  Bindable.swift
//  App
//
//  Created by Ryne Cheow on 14/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

/// Useful when binding a class that has already been provided inputs and produces no outputs.
protocol Bindable {
   func bind()
}
