//
//  PushNotificationRouter.swift
//  Domain
//
//  Created by Ryne Cheow on 28/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

public enum PushNotificationRouter: APIRouter {
   private enum Key: String {
      case token
   }

   case register(String)

   public var relativePath: String {
      switch self {
      case .register:
         return "/api/push/register"
      }
   }

   public var method: HTTPMethodType {
      return .post
   }

   public var parameters: [String: Any]? {
      switch self {
      case let .register(token):
         return [Key.token.rawValue: token]
      }
   }

   public var authenticatable: Bool {
      return true
   }
}
