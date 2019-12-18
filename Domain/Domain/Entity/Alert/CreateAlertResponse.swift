//
//  CreateAlertResponse.swift
//  Domain
//
//  Created by Li Hao Lai on 20/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct CreateAlertResponse: DomainType {
   public let message: String
   public let id: String

   public init(message: String, id: String) {
      self.message = message
      self.id = id
   }
}
