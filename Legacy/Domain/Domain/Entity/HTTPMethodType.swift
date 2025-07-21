//
//  HTTPMethodType.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum HTTPMethodType: String {
   case options = "OPTIONS"
   case get = "GET"
   case head = "HEAD"
   case post = "POST"
   case put = "PUT"
   case patch = "PATCH"
   case delete = "DELETE"
   case trace = "TRACE"
   case connect = "CONNECT"
}
