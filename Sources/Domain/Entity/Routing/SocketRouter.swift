//
//  SocketRoute.swift
//  Domain
//
//  Created by Ryne Cheow on 30/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

protocol SocketRouter: Router {}

public enum PriceSocketRouter: SocketRouter {
   case price(subscriptions: [String])

   public var parameters: [String: Any]? {
      switch self {
      case let .price(subscriptions):
         return ["subs": subscriptions]
      }
   }
}
