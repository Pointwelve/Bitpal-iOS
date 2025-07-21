//
//  AlertList.swift
//  Domain
//
//  Created by James Lai on 17/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

public struct AlertList: DomainType, Equatable {
   public let id: String
   public let alerts: [Alert]
   public let modifyDate: Date

   public init(id: String = defaultKey, alerts: [Alert], modifyDate: Date) {
      self.alerts = alerts
      self.id = id
      self.modifyDate = modifyDate
   }

   public static let defaultKey = "AlertListId"
}
