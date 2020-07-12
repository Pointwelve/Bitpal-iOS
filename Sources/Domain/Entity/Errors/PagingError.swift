//
//  PagingError.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum PagingError: Error {
   case onFinalPage
   case unknownState
}
