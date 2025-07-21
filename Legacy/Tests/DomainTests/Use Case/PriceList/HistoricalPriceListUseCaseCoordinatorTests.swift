//
//  HistoricalPriceListUseCaseCoordinatorTests.swift
//  Domain
//
//  Created by Ryne Cheow on 24/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class HistoricalPriceListUseCaseCoordinatorTests: RxTestCase {
   func testHistoricalPriceListUseCaseExecuted() {
      let expect = expectation(description: "read is loading")
      let date = Date()
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let request = HistoricalPriceListRequest(fromSymbol: currencyB, toSymbol: currencyA,
                                               exchange: exchangeA, aggregate: 6,
                                               limit: 120,
                                               routerType: .day)

      let testableGetAction: (HistoricalPriceListRequest) -> Observable<HistoricalPriceList> = { _ in
         Observable.just(HistoricalPriceList(baseCurrency: request.fromSymbol,
                                             quoteCurrency: request.toSymbol,
                                             exchange: request.exchange,
                                             historicalPrices:
                                             [
                                                HistoricalPrice(time: 147_000, open: 80.0, high: 90.0, low: 81.0,
                                                                close: 88.0, volumeFrom: 1000, volumeTo: 10000),
                                                HistoricalPrice(time: 147_001, open: 80.0, high: 90.0, low: 81.0,
                                                                close: 88.0, volumeFrom: 1000, volumeTo: 10000)
                                             ],
                                             modifyDate: date))
      }

      let coordinator = HistoricalPriceListUseCaseCoordinator(request: request, getAction: testableGetAction)

      coordinator.getResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertNotNil(coordinator.historicalPriceList)
                     XCTAssertEqual(HistoricalPriceList(baseCurrency: currencyB,
                                                        quoteCurrency: currencyA,
                                                        exchange: exchangeA,
                                                        historicalPrices:
                                                        [
                                                           HistoricalPrice(time: 147_000, open: 80.0, high: 90.0, low: 81.0,
                                                                           close: 88.0, volumeFrom: 1000, volumeTo: 10000),
                                                           HistoricalPrice(time: 147_001, open: 80.0, high: 90.0, low: 81.0,
                                                                           close: 88.0, volumeFrom: 1000, volumeTo: 10000)
                                                        ],
                                                        modifyDate: date),
                                    coordinator.historicalPriceList)
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

   func testHistoricalPriceListUseCaseExecutedWithNetworkError() {
      let expect = expectation(description: "Offline error received")
      let currencyA = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let currencyB = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let request = HistoricalPriceListRequest(fromSymbol: currencyB, toSymbol: currencyA,
                                               exchange: exchangeA, aggregate: 6,
                                               limit: 120,
                                               routerType: .day)

      let testableGetAction: (HistoricalPriceListRequest) -> Observable<HistoricalPriceList> = { _ in
         Observable.error(NSError.networkUnreachableError)
      }

      let coordinator = HistoricalPriceListUseCaseCoordinator(request: request, getAction: testableGetAction)

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
