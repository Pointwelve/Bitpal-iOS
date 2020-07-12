//
//  AlertRouter.swift
//  Domain
//
//  Created by Li Hao Lai on 17/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

// swiftlint:disable identifier_name
import Foundation

public enum AlertRouter: APIRouter {
   case alerts

   case create(CreateAlertRequest)

   case delete(String)

   case update(Alert)

   private enum Key: String {
      case pair
      case exchange
      case comparison
      case reference
      case isEnabled

      case id
   }

   public var relativePath: String {
      switch self {
      case .alerts:
         return "/api/alerts"

      case .create:
         return "/api/v2/alerts/create"

      case .delete:
         return "/api/alerts/delete"

      case .update:
         return "/api/alerts/update"
      }
   }

   public var method: HTTPMethodType {
      switch self {
      case .alerts:
         return .get

      case .create:
         return .put

      case .delete:
         return .delete

      case .update:
         return .post
      }
   }

   public var parameters: [String: Any]? {
      switch self {
      case let .create(request):
         return [
            Key.pair.rawValue: request.pair,
            Key.exchange.rawValue: request.exchange,
            Key.comparison.rawValue: request.comparison.rawValue,
            Key.reference.rawValue: request.reference,
            Key.isEnabled.rawValue: request.isEnabled
         ]

      case let .delete(id):
         return [Key.id.rawValue: id]

      case let .update(request):
         return [
            Key.id.rawValue: request.id,
            Key.pair.rawValue: request.pair,
            Key.exchange.rawValue: request.exchange,
            Key.comparison.rawValue: request.comparison.rawValue,
            Key.reference.rawValue: request.reference,
            Key.isEnabled.rawValue: request.isEnabled
         ]
      default:
         return nil
      }
   }

   public var authenticatable: Bool {
      switch self {
      case .alerts:
         return true

      case .create:
         return true

      case .delete:
         return true

      case .update:
         return true
      }
   }
}
