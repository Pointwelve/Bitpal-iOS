//
//  PreferencesUseCaseCoordinatorTests.swift
//  Domain
//
//  Created by Ryne Cheow on 5/6/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import RxSwift
import XCTest

class PreferencesUseCaseCoordinatorTests: RxTestCase {
   func testReadBeginsInLoadingState() {
      let expect = expectation(description: "read is loading")
      let coordinator = PreferencesUseCaseCoordinator(preferences: Preferences(), preferredLanguageAction: { .en }, preferredThemeAction: { .dark }, preferredChartTypeAction: { .line }, readAction: { .never() }, writeAction: { _ in .never() })
      coordinator.readResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(.with(_, progress)):
               if progress == .loading {
                  expect.fulfill()
               }
            default:
               break
            }
         })
         .disposed(by: disposeBag)
      waitForExpectations(timeout: 1, handler: { _ in })
   }

   func testWriteBeginsInLoadingState() {
      let expect = expectation(description: "write is loading")
      let coordinator = PreferencesUseCaseCoordinator(preferences: Preferences(), preferredLanguageAction: { .en }, preferredThemeAction: { .dark }, preferredChartTypeAction: { .line }, readAction: { .never() }, writeAction: { _ in .never() })
      coordinator.writeResult()
         .subscribe(onNext: { result in
            switch result {
            case let .content(.with(_, progress)):
               if progress == .loading {
                  expect.fulfill()
               }
            default:
               break
            }
         })
         .disposed(by: disposeBag)
      waitForExpectations(timeout: 1, handler: { _ in })
   }

   func testReadResultingInParseErrorWritesInstalledFlag() {
      let expect = expectation(description: "wrote installed")
      let coordinator = PreferencesUseCaseCoordinator(preferences: Preferences(), preferredLanguageAction: { .en }, preferredThemeAction: { .dark }, preferredChartTypeAction: { .line }, readAction: { .error(ParseError.parseFailed) }, writeAction: { preferences in
         XCTAssertTrue(preferences.installed)
         expect.fulfill()
         return .never()
      })
      coordinator.readResult()
         .subscribe()
         .disposed(by: disposeBag)
      waitForExpectations(timeout: 1, handler: { _ in })
   }

   func testReplacingLanguage() {
      let coordinator = PreferencesUseCaseCoordinator(preferences: Preferences(), preferredLanguageAction: { .en }, preferredThemeAction: { .dark }, preferredChartTypeAction: { .line }, readAction: { .never() }, writeAction: { _ in .never() })
      XCTAssertNil(coordinator.preferences.language)
      let replaced = coordinator.replacing(language: .en)
      XCTAssertEqual(replaced.preferences.language, .en)
   }

   func testReplacingInstalled() {
      let coordinator = PreferencesUseCaseCoordinator(preferences: Preferences(), preferredLanguageAction: { .en }, preferredThemeAction: { .dark }, preferredChartTypeAction: { .line }, readAction: { .never() }, writeAction: { _ in .never() })
      XCTAssertFalse(coordinator.preferences.installed)
      let replaced = coordinator.replacing(installed: true)
      XCTAssertTrue(replaced.preferences.installed)
   }

   func testReplacingNeedsReset() {
      let coordinator = PreferencesUseCaseCoordinator(preferences: Preferences(), preferredLanguageAction: { .en }, preferredThemeAction: { .dark }, preferredChartTypeAction: { .line }, readAction: { .never() }, writeAction: { _ in .never() })
      XCTAssertFalse(coordinator.needsReset)
      let replaced = coordinator.replacing(needsReset: true, needsLocalization: false)
      XCTAssertTrue(replaced.needsReset)
   }

   func testReplacingNeedsLocalization() {
      let coordinator = PreferencesUseCaseCoordinator(preferences: Preferences(), preferredLanguageAction: { .en }, preferredThemeAction: { .dark }, preferredChartTypeAction: { .line }, readAction: { .never() }, writeAction: { _ in .never() })
      XCTAssertFalse(coordinator.needsLocalization)
      let replaced = coordinator.replacing(needsReset: false, needsLocalization: true)
      XCTAssertTrue(replaced.needsLocalization)
   }

   func testReplacingLanguageRequiresReset() {
      let coordinator = PreferencesUseCaseCoordinator(preferences: .init(language: .default, databaseName: "test"), preferredLanguageAction: { .en }, preferredThemeAction: { .dark }, preferredChartTypeAction: { .line }, readAction: { .never() }, writeAction: { _ in .never() })
      XCTAssertFalse(coordinator.needsReset)
      let replaced = coordinator.replacing(language: .en)
      XCTAssertTrue(replaced.needsReset)
   }
}
