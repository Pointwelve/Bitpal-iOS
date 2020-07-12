//
//  CurrencyDetailUseCaseCoordinatorTests.swift
//  Domain
//
//  Created by Kok Hong Choo on 28/8/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class CurrencyDetailUseCaseCoordinatorTests: RxTestCase {
   func testCurrencyDetailUseCaseExecuted() {
      let expect = expectation(description: "read is loading")
      let date = Date()
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")
      let request = GetCurrencyDetailRequest(currencyPair: CurrencyPair(baseCurrency: currencyA,
                                                                        quoteCurrency: currencyB,
                                                                        exchange: exchangeA,
                                                                        price: 10.0))

      let currencyDetail = CurrencyDetail(fromCurrency: "USD",
                                          toCurrency: "BTC",
                                          price: 10.0,
                                          volume24Hour: 0.0,
                                          open24Hour: 0.0,
                                          high24Hour: 0.0,
                                          low24Hour: 0.0,
                                          change24Hour: 0.0,
                                          changePct24hour: 0.0,
                                          fromDisplaySymbol: "a",
                                          toDisplaySymbol: "b",
                                          marketCap: 40.0,
                                          exchange: "Gemini",
                                          modifyDate: date)

      let testableGetAction: (GetCurrencyDetailRequest) -> Observable<CurrencyDetail> = { _ in
         Observable.just(currencyDetail)
      }

      let coordinator = CurrencyDetailUseCaseCoordinator(request: request, getAction: testableGetAction)

      coordinator.getResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertNotNil(coordinator.currencyDetail)
                     XCTAssertEqual(coordinator.currencyDetail, currencyDetail)
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
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let request = GetCurrencyDetailRequest(currencyPair: CurrencyPair(baseCurrency: currencyA,
                                                                        quoteCurrency: currencyB,
                                                                        exchange: exchangeA,
                                                                        price: 10.0))

      let testableGetAction: (GetCurrencyDetailRequest) -> Observable<CurrencyDetail> = { _ in
         Observable.error(NSError.networkUnreachableError)
      }

      let coordinator = CurrencyDetailUseCaseCoordinator(request: request, getAction: testableGetAction)

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
