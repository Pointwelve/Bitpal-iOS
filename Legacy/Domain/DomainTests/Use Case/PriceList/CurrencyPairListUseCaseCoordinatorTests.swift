//
//  CurrencyPairListUseCaseCoordinatorTests.swift
//  Domain
//
//  Created by Li Hao Lai on 16/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class CurrencyPairListUseCaseCoordinatorTests: RxTestCase {
   func testCurrencyPairListUseCaseExecuted() {
      let expect = expectation(description: "read is loading")
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let pairs = [
         CurrencyPairGroup(id: "", baseCurrency: currencyB,
                           quoteCurrency: currencyA, exchanges: [exchangeA])
      ]

      let testableGetAction: (String) -> Observable<CurrencyPairList> = { _ in
         Observable.just(CurrencyPairList(id: "PriceList",
                                          currencyPairs: pairs,
                                          modifyDate: Date()))
      }

      let coordinator = CurrencyPairListUseCaseCoordinator(getAction: testableGetAction)

      coordinator.getResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertNotNil(coordinator.priceList)
                     XCTAssertEqual(CurrencyPairList(id: "PriceList",
                                                     currencyPairs: pairs,
                                                     modifyDate: Date()),
                                    coordinator.priceList)
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

   func testPriceListUseCaseExecutedWithNetworkError() {
      let expect = expectation(description: "Offline error received")
      let testableGetAction: (String) -> Observable<CurrencyPairList> = { _ in
         Observable.error(NSError.networkUnreachableError)
      }

      let coordinator = CurrencyPairListUseCaseCoordinator(getAction: testableGetAction)

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
