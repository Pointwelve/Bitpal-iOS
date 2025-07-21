//
//  DeviceFingerprint.swift
//  Domain
//
//  Created by James Lai on 19/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct DeviceFingerprint: DomainType {
   public let data: String

   public init(data: String) {
      self.data = data
   }
}
