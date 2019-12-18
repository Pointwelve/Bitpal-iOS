//
//  CacheError.swift
//  Domain
//
//  Created by Ryne Cheow on 17/4/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum CacheError: Error {
   case invalid
   case notFound
   case expired
   case empty
}
