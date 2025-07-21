//
//  AnonymousMigrationRequest.swift
//  Domain
//
//  Created by James Lai on 21/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct AnonymousMigrationRequest: RequestType {
   public let anonymousIdentifier: String
   public let override: Bool?

   public init(anonymousIdentifier: String, override: Bool? = nil) {
      self.anonymousIdentifier = anonymousIdentifier
      self.override = override
   }
}
