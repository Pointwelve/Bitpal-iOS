//
//  CreateAlertUIData.swift
//  App
//
//  Created by Li Hao Lai on 31/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation

struct CreateAlertUIData {
   let id: String?
   let quoteSymbol: String
   let exchange: String
   let comparison: AlertComparison
   let reference: Decimal
   let isEnabled: Bool
   let isUpdate: Bool

   init(id: String? = nil,
        quoteSymbol: String,
        exchange: String,
        comparison: AlertComparison = .lessThanOrEqual,
        reference: Decimal,
        isEnabled: Bool = true,
        isUpdate: Bool = false) {
      self.id = id
      self.quoteSymbol = quoteSymbol
      self.exchange = exchange
      self.comparison = comparison
      self.reference = reference
      self.isEnabled = isEnabled
      self.isUpdate = isUpdate
   }

   static let emptyData: CreateAlertUIData = {
      CreateAlertUIData(quoteSymbol: "", exchange: "", reference: 0.0)
   }()
}
