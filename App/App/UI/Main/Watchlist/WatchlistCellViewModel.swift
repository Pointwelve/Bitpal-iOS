//
//  WatchlistCellViewModel.swift
//  App
//
//  Created by Hong on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Domain
import Foundation
import RxCocoa
import RxSwift
import UIKit

class WatchlistCellViewModel: ViewModelType {
   struct Input {
      let currencyPair: CurrencyPair
      let streamPrice: Driver<StreamPrice>
   }

   struct Output {
      let baseCurrencyText: String
      let quoteCurrencyText: String
      let priceChange: Driver<UIColor>
      let priceText: Driver<String>
   }

   func transform(input: Input) -> Output {
      let baseCurrencyText = input.currencyPair.baseCurrency
      let quoteCurrencyText = input.currencyPair.quoteCurrency

      let selectedStreamPrice = input.streamPrice.filter {
         $0.baseCurrency == baseCurrencyText && $0.quoteCurrency == quoteCurrencyText
      }

      let priceText = selectedStreamPrice.map { "\($0.price)" }.startWith("\(input.currencyPair.price)")

      // Will Always start with unchagned
      let priceChange = selectedStreamPrice.map { $0.priceChange.color }.startWith(PriceChange.unchanged.color)

      return Output(baseCurrencyText: baseCurrencyText.rawValue, quoteCurrencyText: quoteCurrencyText.rawValue,
                    priceChange: priceChange, priceText: priceText)
   }
}
