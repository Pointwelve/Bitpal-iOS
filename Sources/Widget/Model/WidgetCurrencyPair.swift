//
//  WidgetCurrencyPair.swift
//  Widget
//
//  Created by James Lai on 7/9/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Foundation

struct WidgetCurrencyPair {
   let exchange: String
   let baseCurrency: String
   let quoteCurrency: String
   var price: Double?
   var changePct: Double?

   init(exchange: String, baseCurrency: String, quoteCurrency: String, price: Double? = nil, changePct: Double? = nil) {
      self.exchange = exchange
      self.baseCurrency = baseCurrency
      self.quoteCurrency = quoteCurrency
      self.price = price
      self.changePct = changePct
   }
}
