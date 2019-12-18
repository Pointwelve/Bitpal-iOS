//
//  AlertListData.swift
//  Data
//
//  Created by James Lai on 17/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct AlertListData: DataType, Equatable, Modifiable {
   let id: String
   let alerts: [AlertData]
   var modifyDate: Date
}
