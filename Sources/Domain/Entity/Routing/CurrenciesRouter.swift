//
//  CurrenciesRouter.swift
//  Domain
//
//  Created by Ryne Cheow on 11/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public enum CurrenciesRouter: APIRouter {
   case currencies

   public var relativePath: String {
      switch self {
      case .currencies:
         return "/api/v2/currencies"
      }
   }

   public var method: HTTPMethodType {
      return .get
   }
}
