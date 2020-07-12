//
//  AuthenticationToken.swift
//  Domain
//
//  Created by Ryne Cheow on 8/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct AuthenticationToken: DomainType {
   public let token: String

   public init(token: String) {
      self.token = token
   }
}
