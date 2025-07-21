//
//  WatchlistRouter.swift
//  Domain
//
//  Created by Ryne Cheow on 5/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

public enum WatchlistRouter: APIRouter {
   private enum Key: String {
      case watchlist
   }

   case retrieve
   case update([[String: Any]])

   public var relativePath: String {
      return "/api/v2/watchlist"
   }

   public var method: HTTPMethodType {
      switch self {
      case .update:
         return .post
      case .retrieve:
         return .get
      }
   }

   public var parameters: [String: Any]? {
      switch self {
      case let .update(data):
         return [Key.watchlist.rawValue: data]
      default:
         return nil
      }
   }

   public var authenticatable: Bool {
      return true
   }
}
