//
//  WatchlistCellViewModel.swift
//  App
//
//  Created by Hong on 13/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

import Charts
import Domain
import Foundation
import RxCocoa
import RxSwift
import UIKit

final class WatchlistCellViewModel: TransformableViewModelType {
   struct Input {
      let currencyPair: MutableBox<CurrencyPair>
      let streamPrice: Driver<StreamPrice>
      let historicalPriceAPI: (HistoricalPriceListRequest) -> Driver<HistoricalPriceList>
   }

   struct Output {
      let baseCurrencyText: String
      let quoteCurrencyText: String
      let exchange: Exchange
      let priceText: Driver<String>
      let updateCryptoCurrency: Driver<Void>
      let priceChangePctText: Driver<String>
      let priceChangePctPriceChange: Driver<PriceChange>
      let savePrice: Driver<Void>
      let chartData: Driver<ChartData>
   }

   func transform(input: Input) -> Output {
      let currencyPair = input.currencyPair.value

      let baseCurrencyText = currencyPair.baseCurrency
      let quoteCurrencyText = currencyPair.quoteCurrency

      let selectedStreamPrice = input.streamPrice.filter {
         $0.baseCurrency.symbol == baseCurrencyText.symbol
            && $0.quoteCurrency.symbol == quoteCurrencyText.symbol
            && $0.exchange == currencyPair.exchange
      }
      let cryptoCurrency =
         CryptoCurrency(baseCurrency: currencyPair.baseCurrency,
                        quoteCurrency: currencyPair.quoteCurrency)

      let updateCryptoCurrency = selectedStreamPrice.do(onNext: { price in
         cryptoCurrency.update(with: price)
      }).void()

      let price = cryptoCurrency.rx.observe(Double.self, "price").filterNil()

      let savePrice = price.filter { $0 != 0.0 }
         .flatMapLatest { priceDollar -> Observable<CurrencyPair> in
            let newCurrencyPair = CurrencyPair(baseCurrency: currencyPair.baseCurrency,
                                               quoteCurrency: currencyPair.quoteCurrency,
                                               exchange: currencyPair.exchange,
                                               price: priceDollar)

            input.currencyPair.value = newCurrencyPair
            return .just(currencyPair)
         }
         .void()
         .asDriver()
      let initialPrice = "\(currencyPair.price == 0.0 ? "-" : "\(currencyPair.price.formatUsingSignificantDigits())")"
      let priceText = price
         .filter { $0 != 0.0 }
         .map { "\($0.formatUsingSignificantDigits())" }
         .startWith(initialPrice)
         .asDriver(onErrorJustReturn: "-")

      let priceChangePct = Observable.combineLatest(cryptoCurrency
         .rx.observe(Double.self, "price").skip(1).filterNil(),
                                                    cryptoCurrency
            .rx.observe(Double.self, "open24Hour").skip(1).filterNil()) { price, open24Hour -> Double in
         let change24H = price - open24Hour
         let change24HPct = change24H / open24Hour * 100

         return change24HPct
      }

      let priceChangePctText = priceChangePct
         .map { String(format: "%@%.2f%%", $0 > 0 ? "+" : "", $0) }
         .asDriver(onErrorJustReturn: "-")

      let priceChangePctPriceChange = priceChangePct.asDriver(onErrorJustReturn: 0.0)
         .map { $0.priceChangeIn24HPct() }

      let aggregate = ChartAggregateMinute.thirty
      let limit = aggregate.limitHour(limit: .twentyFour)
      // 60 Minutes with 24 hours data
      let historicalPriceListRequest = HistoricalPriceListRequest(fromSymbol: input.currencyPair.value.baseCurrency,
                                                                  toSymbol: input.currencyPair.value.quoteCurrency,
                                                                  exchange: input.currencyPair.value.exchange,
                                                                  aggregate: aggregate.rawValue,
                                                                  limit: limit,
                                                                  routerType: .minute)

      let chartData = input.historicalPriceAPI(historicalPriceListRequest)
         .map { ChartDataHelper.convertToChartData(from: $0.historicalPrices) }

      return Output(baseCurrencyText: baseCurrencyText.symbol,
                    quoteCurrencyText: quoteCurrencyText.symbol,
                    exchange: currencyPair.exchange,
                    priceText: priceText,
                    updateCryptoCurrency: updateCryptoCurrency,
                    priceChangePctText: priceChangePctText,
                    priceChangePctPriceChange: priceChangePctPriceChange,
                    savePrice: savePrice,
                    chartData: chartData)
   }
}
