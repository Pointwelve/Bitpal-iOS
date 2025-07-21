//
//  WidgetPreferenceUseCaseCoordinatorTests.swift
//  DomainTests
//
//  Created by Kok Hong Choo on 1/10/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class WidgetPreferenceUseCaseCoordinatorTests: RxTestCase {
   func testWidgetPreferenceReadSuccess() {
      let expect = expectation(description: "read is loading")
      let preferences = Preferences(language: nil, theme: nil, databaseName: "test", installed: true)

      let testableReadAction: () -> Observable<Preferences> = {
         Observable.just(preferences)
      }

      let testableWriteAction: (Preferences) -> Observable<Preferences> = { _ in
         Observable.just(preferences)
      }

      let coordinator = WidgetPreferenceUseCaseCoordinator(preferences: preferences,
                                                           readAction: testableReadAction,
                                                           writeAction: testableWriteAction)

      coordinator.readResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertNotNil(coordinator.preferences)
                     XCTAssertEqual(preferences,
                                    coordinator.preferences)
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

   func testWidgetPreferenceWriteSuccess() {
      let expect = expectation(description: "write is loading")
      let preferences = Preferences(language: nil, theme: nil, databaseName: "test", installed: true)

      let testableReadAction: () -> Observable<Preferences> = {
         Observable.just(preferences)
      }

      let testableWriteAction: (Preferences) -> Observable<Preferences> = { _ in
         Observable.just(preferences)
      }

      let coordinator = WidgetPreferenceUseCaseCoordinator(preferences: preferences,
                                                           readAction: testableReadAction,
                                                           writeAction: testableWriteAction)

      coordinator.writeResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(content):
               switch content {
               case let .with(coordinator, condition):
                  switch condition {
                  case .full:
                     XCTAssertNotNil(coordinator.preferences)
                     XCTAssertEqual(preferences,
                                    coordinator.preferences)
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

   func testReadPreferencesExecutedWithNetworkError() {
      let expect = expectation(description: "Offline Error")
      let preferences = Preferences(language: nil, theme: nil, databaseName: "test", installed: true)

      let testableReadAction: () -> Observable<Preferences> = {
         Observable.error(NSError.networkUnreachableError)
      }

      let testableWriteAction: (Preferences) -> Observable<Preferences> = { _ in
         Observable.error(NSError.networkUnreachableError)
      }

      let coordinator = WidgetPreferenceUseCaseCoordinator(preferences: preferences,
                                                           readAction: testableReadAction,
                                                           writeAction: testableWriteAction)

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

   func testWritePreferencesExecutedWithNetworkError() {
      let expect = expectation(description: "Offline Error")
      let preferences = Preferences(language: nil, theme: nil, databaseName: "test", installed: true)

      let testableReadAction: () -> Observable<Preferences> = {
         Observable.error(NSError.networkUnreachableError)
      }

      let testableWriteAction: (Preferences) -> Observable<Preferences> = { _ in
         Observable.error(NSError.networkUnreachableError)
      }

      let coordinator = WidgetPreferenceUseCaseCoordinator(preferences: preferences,
                                                           readAction: testableReadAction,
                                                           writeAction: testableWriteAction)

      coordinator.writeResult()
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
