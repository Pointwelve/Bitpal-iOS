//
//  AlertData.swift
//  Data
//
//  Created by James Lai on 17/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct AlertData: DataType, Equatable {
   let id: String
   let base: String
   let quote: String
   let exchange: String
   let comparison: AlertComparison
   let reference: Decimal
   let isEnabled: Bool
}
