//
//  Router.swift
//  Domain
//
//  Created by Ryne Cheow on 1/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public protocol Router {
   var parameters: [String: Any]? { get }
}

public protocol APIRouter: Router {
   var method: HTTPMethodType { get }
   var relativePath: String { get }
   var query: [URLQueryItem]? { get }
   var formParameters: [String: Any]? { get }
   var overridePath: String? { get }
   var authenticatable: Bool { get }
}

extension APIRouter {
   public var parameters: [String: Any]? {
      return nil
   }

   public var query: [URLQueryItem]? {
      return nil
   }

   public var formParameters: [String: Any]? {
      return nil
   }

   public var overridePath: String? {
      return nil
   }

   public var authenticatable: Bool {
      return false
   }
}
