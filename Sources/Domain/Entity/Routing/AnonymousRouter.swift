//
//  AnonymousMigrationRouter.swift
//  Domain
//
//  Created by James Lai on 21/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

public enum AnonymousRouter: APIRouter {
   private enum ParameterKey: String {
      case anonymousIdentifier
      case override
   }

   case migration(anonymousIdentifier: String, override: Bool?)

   public var relativePath: String {
      switch self {
      case .migration:
         return "/api/migration"
      }
   }

   public var method: HTTPMethodType {
      return .post
   }

   public var parameters: [String: Any]? {
      switch self {
      case let .migration(anonymousIdentifier, override):
         var params: [String: Any] = [ParameterKey.anonymousIdentifier.rawValue: anonymousIdentifier]

         guard let override = override else {
            return params
         }

         params[ParameterKey.override.rawValue] = override

         return params
      }
   }

   public var authenticatable: Bool {
      return true
   }
}
