//
//  StreamPriceUseCaseCoordinatorTests.swift
//  Domain
//
//  Created by Ryne Cheow on 24/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class StreamPriceUseCaseCoordinatorTests: RxTestCase {
   func testStreamPriceUseCaseExecuted() {
      let expect = expectation(description: "read is loading")
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyC = Currency(id: "ETH", name: "Ethereum", symbol: "ETH")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let pairs = [
         CurrencyPair(baseCurrency: currencyB,
                      quoteCurrency: currencyA, exchange: exchangeA, price: 1.0),
         CurrencyPair(baseCurrency: currencyC,
                      quoteCurrency: currencyB, exchange: exchangeA, price: 1.0)
      ]
      let request = GetPriceListRequest(currencyPairs: pairs)

      let testableStreamAction: (GetPriceListRequest) -> Observable<StreamPrice> = { _ in
         Observable.just(StreamPrice(type: .current, exchange: exchangeA, baseCurrency: currencyB,
                                     quoteCurrency: currencyA, priceChange: .down, price: 2000.0, bid: 123,
                                     offer: 124, lastUpdateTimeStamp: 147_000, avg: 2000, lastVolume: 1000,
                                     lastVolumeTo: 10000, lastTradeId: 88, volumeHour: 1000, volumeHourTo: 10000,
                                     volume24h: 1000, volume24hTo: 10000, openHour: 123_132, highHour: 123_551,
                                     lowHour: 123_555, open24Hour: 199, high24Hour: 2999, low24Hour: 1888,
                                     lastMarket: 1222, mask: "ce64"))
      }

      let coordinator = StreamPriceUseCaseCoordinator(request: request, streamAction: testableStreamAction)

      coordinator.getResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertNotNil(coordinator.streamPrice)
                     XCTAssertEqual(StreamPrice(type: .current, exchange: exchangeA, baseCurrency: currencyB,
                                                quoteCurrency: currencyA, priceChange: .down, price: 2000.0, bid: 123,
                                                offer: 124, lastUpdateTimeStamp: 147_000, avg: 2000, lastVolume: 1000,
                                                lastVolumeTo: 10000, lastTradeId: 88, volumeHour: 1000, volumeHourTo: 10000,
                                                volume24h: 1000, volume24hTo: 10000, openHour: 123_132, highHour: 123_551,
                                                lowHour: 123_555, open24Hour: 199, high24Hour: 2999, low24Hour: 1888,
                                                lastMarket: 1222, mask: "ce64"), coordinator.streamPrice)
                     expect.fulfill()
                  default:
                     break
                  }
               }

            default:
               break
            }
         })
         .disposed(by: disposeBag)

      waitForExpectations(timeout: 1, handler: { _ in })
   }

   func testStreamPriceUseCaseExecutedWithNetworkError() {
      let expect = expectation(description: "Offline error received")
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyC = Currency(id: "ETH", name: "Ethereum", symbol: "ETH")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")
      let pairs = [
         CurrencyPair(baseCurrency: currencyB,
                      quoteCurrency: currencyA, exchange: exchangeA, price: 1.0),
         CurrencyPair(baseCurrency: currencyC,
                      quoteCurrency: currencyA, exchange: exchangeA, price: 1.0)
      ]
      let request = GetPriceListRequest(currencyPairs: pairs)

      let testableStreamAction: (GetPriceListRequest) -> Observable<StreamPrice> = { _ in
         Observable.error(NSError.networkUnreachableError)
      }

      let coordinator = StreamPriceUseCaseCoordinator(request: request, streamAction: testableStreamAction)

      coordinator.getResult()
         .subscribe(onNext: { result in
            switch result {
            case let .failure(failure):
               switch failure {
               case .offline:
                  expect.fulfill()
               default:
                  break
               }
            default:
               break
            }
         })
         .disposed(by: disposeBag)

      waitForExpectations(timeout: 1, handler: { _ in })
   }
}
