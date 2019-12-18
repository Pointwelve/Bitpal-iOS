//
//  AuthenticationRouter.swift
//  Domain
//
//  Created by Ryne Cheow on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

public enum AuthenticationRouter: APIRouter {
   private enum ParameterKey: String {
      case identifier
   }

   case authenticate(identifier: String)

   public var relativePath: String {
      switch self {
      case .authenticate:
         return "/api/auth"
      }
   }

   public var method: HTTPMethodType {
      return .post
   }

   public var parameters: [String: Any]? {
      switch self {
      case let .authenticate(identifier):
         return [ParameterKey.identifier.rawValue: identifier]
      }
   }
}
