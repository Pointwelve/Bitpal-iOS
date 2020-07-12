//
//  WatchlistAddCoinCellViewModel.swift
//  App
//
//  Created by Li Hao Lai on 25/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain

final class WatchlistAddCoinCellViewModel: TransformableViewModelType {
   struct Input {
      let currencyPairGroup: CurrencyPairGroup
   }

   struct Output {
      let baseCurrencyText: String
      let quoteCurrencyText: String
   }

   init() {}

   func transform(input: Input) -> Output {
      let baseCurrencyText = input.currencyPairGroup.quoteCurrency.symbol
      let quoteCurrencyText = input.currencyPairGroup.quoteCurrency.localizedFullname

      return Output(baseCurrencyText: baseCurrencyText,
                    quoteCurrencyText: quoteCurrencyText)
   }
}
