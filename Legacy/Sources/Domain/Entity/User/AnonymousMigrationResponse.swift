//
//  AnonymousMigrationResponse.swift
//  Domain
//
//  Created by Li Hao Lai on 24/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct AnonymousMigrationResponse: DomainType {
   public let success: Bool?
   public let numOfWatchlist: Int?
   public let numOfPriceAlert: Int?

   public init(success: Bool?, numOfWatchlist: Int?, numOfPriceAlert: Int?) {
      self.success = success
      self.numOfWatchlist = numOfWatchlist
      self.numOfPriceAlert = numOfPriceAlert
   }
}
