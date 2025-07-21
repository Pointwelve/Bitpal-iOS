//
//  OfflineOnlyLoadStateTests.swift
//  App
//
//  Created by Ryne Cheow on 5/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Bitpal
import Domain
import Foundation
import XCTest

class OfflineOnlyLoadStateTests: XCTestCase {
   var loadState: LoadState!

   override func setUp() {
      loadState = LoadState()
   }

   override func tearDown() {
      loadState = nil
   }

   // Always test the result of the display state
   var displayState: LoadState {
      return loadState.prepareForDisplay(strategy: .offlineOnly)
   }

   func testReadyInLoadingState() {
      loadState.setLoading(true)
      XCTAssertTrue(displayState.contains(.ready))
      XCTAssertFalse(displayState.contains(.offline))

      loadState.setLoading(false)
      XCTAssertFalse(displayState.contains(.loading))

      loadState = [.expired, .pageAvailable]
      XCTAssertTrue(loadState.title == "")
      XCTAssertTrue(loadState.message == "")
   }

   func testReadyInEmptyState() {
      loadState.setEmpty()
      XCTAssertTrue(displayState.contains(.ready))
      XCTAssertFalse(displayState.contains(.offline))
      XCTAssertTrue("empty.view.title".localized() == loadState.title)
      XCTAssertTrue("empty.view.message".localized() == loadState.message)
   }

   func testReadyInErrorState() {
      loadState.setError()
      XCTAssertTrue(displayState.contains(.ready))
      XCTAssertFalse(displayState.contains(.offline))
      XCTAssertTrue("error.sorry.title".localized() == loadState.title)
      XCTAssertTrue("error.sorry.message".localized() == loadState.message)
   }

   func testReadyInReadyState() {
      loadState.setReady()
      XCTAssertTrue(displayState.contains(.ready))
      XCTAssertFalse(displayState.contains(.offline))
   }

   func testOfflineInOfflineState() {
      loadState.setOffline(true)
      XCTAssertFalse(displayState.contains(.ready))
      XCTAssertTrue(displayState.contains(.offline))
      XCTAssertTrue("offline.view.title".localized() == loadState.title)
      XCTAssertTrue("offline.view.message".localized() == loadState.message)

      loadState.setOffline(false)
      XCTAssertFalse(displayState.contains(.offline))
   }

   func testExpiredState() {
      loadState = [.empty]
      loadState.setExpired(true)
      XCTAssertFalse(displayState.contains(.empty))
      XCTAssertTrue(loadState.contains(.expired))

      loadState.setExpired(false)
      XCTAssertFalse(displayState.contains(.expired))
   }

   func testUnreadyState() {
      loadState.setUnready()
      XCTAssertFalse(loadState.contains(.ready))
   }

   func testStrategyManual() {
      loadState = [.ready]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .manual) == .ready)

      loadState = [.offline]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .manual) == .offline)

      loadState = [.empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .manual) == [.empty])
   }

   func testStrategyWeb() {
      loadState = [.loading, .offline]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .web) == [.offline])

      loadState = [.loading, .empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .web) == .loading)

      loadState = [.error, .offline]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .web) == [.offline])

      loadState = [.error, .empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .web) == [.error])

      loadState = [.empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .web) == [.ready])
   }

   func testStrategyStaticWeb() {
      loadState = [.loading, .empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .staticWeb) == .loading)

      loadState = [.error, .empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .staticWeb) == [.error])

      loadState = [.empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .staticWeb) == [.ready])
   }

   func testStrategyOfflineAndReady() {
      loadState = [.offline, .ready]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .offlineAndReady).contains(.offline))
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .offlineAndReady).contains(.ready))

      loadState = [.empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .offlineAndReady) == [])
   }

   func testStrategyDefault() {
      loadState = [.loading, .ready]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .default).contains(.loading))
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .default).contains(.ready))

      loadState = [.empty, .offline]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .default).contains(.offline))

      loadState = [.empty, .error]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .default).contains(.error))
      loadState = [.empty]
      XCTAssertTrue(loadState.prepareForDisplay(strategy: .default).contains(.empty))
   }
}
