//
//  GetWatchlistUseCaseCoordinatorTests.swift
//  DomainTests
//
//  Created by Kok Hong Choo on 1/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class GetWatchlistUseCaseCoordinatorTests: RxTestCase {
   func testGetWatchlistSuccees() {
      let expect = expectation(description: "read is loading")
      let currencyA = Currency(id: "USD", name: "US Dollar", symbol: "USD")
      let currencyB = Currency(id: "BTC", name: "Bitcoin", symbol: "BTC")
      let exchangeA = Exchange(id: "Gemini", name: "Gemini")

      let currencyPair = CurrencyPair(baseCurrency: currencyA,
                                      quoteCurrency: currencyB,
                                      exchange: exchangeA,
                                      price: 0.0)

      let date = Date()
      let expectedWatchlist = Watchlist(id: "Watchlist", currencyPairs: [currencyPair], modifyDate: date)

      let testableGetAction: () -> Observable<Watchlist> = {
         Observable.just(expectedWatchlist)
      }

      let coordinator = GetWatchlistUseCaseCoordinator(readAction: testableGetAction)

      coordinator.readResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertNotNil(coordinator.watchList)
                     XCTAssertEqual(expectedWatchlist,
                                    coordinator.watchList)
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

   func testGetAllWatchlistUseCaseExecutedWithNetworkError() {
      let expect = expectation(description: "Offline error received")

      let testableReadAction: () -> Observable<Watchlist> = {
         Observable.error(NSError.networkUnreachableError)
      }

      let coordinator = GetWatchlistUseCaseCoordinator(readAction: testableReadAction)

      coordinator.readResult()
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
