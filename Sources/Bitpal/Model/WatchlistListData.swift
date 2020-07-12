//
//  WatchlistListData.swift
//  App
//
//  Created by Kok Hong Choo on 13/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import RxDataSources

struct WatchlistListData {
   var header: String
   var items: [Item]
}

extension WatchlistListData: SectionModelType {
   typealias Item = MutableBox<CurrencyPair>

   init(original: WatchlistListData, items: [Item]) {
      self = original
      self.items = items
   }
}
