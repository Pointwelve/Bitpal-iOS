//
//  WatchlistAddCoinListData.swift
//  App
//
//  Created by Li Hao Lai on 25/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxDataSources

struct WatchlistAddCoinListData {
   var header: Currency
   var items: [Item]
}

extension WatchlistAddCoinListData: SectionModelType {
   typealias Item = CurrencyPairGroup

   init(original: WatchlistAddCoinListData, items: [Item]) {
      self = original
      self.items = items
   }
}
