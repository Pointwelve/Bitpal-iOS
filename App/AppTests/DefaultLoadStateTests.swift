//
//  DefaultLoadStateTests.swift
//  App
//
//  Created by Ryne Cheow on 5/5/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import App
import Domain
import Foundation
import XCTest

class DefaultLoadStateTests: XCTestCase {
   var loadState: LoadState!

   override func setUp() {
      loadState = LoadState()
   }

   override func tearDown() {
      loadState = nil
   }

   // Always test the result of the display state
   var displayState: LoadState {
      return loadState.prepareForDisplay(strategy: .default)
   }

   func testLoadingIsNotReturnedIfOffline() {
      loadState.setLoading(true)
      loadState.setOffline(true)
      XCTAssertFalse(displayState.contains(.loading))
   }

   func testLoadingAndReadyAreCombinedAndReturned() {
      // ready must be set first, this is the case where we have data
      // but are trying to do another action on top of the screen
      loadState.setReady()
      loadState.setLoading(true)
      XCTAssertTrue(displayState.contains(.loading))
      XCTAssertTrue(displayState.contains(.ready))
   }

   func testLoadingAndReadyAreCombinedAndReturnedAndOtherStatesAreIgnored() {
      // test that only these two states are returned
      loadState = [.loading, .ready, .empty, .error]
      XCTAssertTrue(displayState.contains(.loading))
      XCTAssertTrue(displayState.contains(.ready))
      XCTAssertFalse(displayState.contains(.empty))
      XCTAssertFalse(displayState.contains(.error))
   }

   func testOfflineIsReturnedIfLoadingAndOffline() {
      loadState.setLoading(true)
      loadState.setOffline(true)
      XCTAssertTrue(displayState.contains(.offline))
   }

   func testOfflineTrumpsError() {
      loadState.setError()
      loadState.setOffline(true)
      XCTAssertTrue(displayState.contains(.offline))
      XCTAssertFalse(displayState.contains(.error))
   }

   func testErrorTrumpsEmpty() {
      loadState.setEmpty()
      loadState.setError()
      XCTAssertTrue(displayState.contains(.error))
      XCTAssertFalse(displayState.contains(.empty))
   }

   func testErrorIsInvalidatedIfLoading() {
      loadState.setError()
      loadState.setLoading(true)
      XCTAssertTrue(displayState.contains(.loading))
      XCTAssertFalse(displayState.contains(.error))
   }

   func testEmptyIsInvalidatedIfLoading() {
      loadState.setEmpty()
      loadState.setLoading(true)
      XCTAssertTrue(displayState.contains(.loading))
      XCTAssertFalse(displayState.contains(.empty))
   }

   // MARK: - Expired

   func testExpiredIsIgnored() {
      loadState.setExpired(true)
      XCTAssertFalse(displayState.contains(.expired))
   }

   // MARK: - Loading

   func testLoadingIsResetIfReady() {
      loadState.setLoading(true)
      XCTAssertTrue(displayState.contains(.loading))
      loadState.setReady()
      XCTAssertFalse(displayState.contains(.loading))
   }

   func testLoadingIsResetIfEmpty() {
      loadState.setLoading(true)
      XCTAssertTrue(displayState.contains(.loading))
      loadState.setEmpty()
      XCTAssertFalse(displayState.contains(.loading))
   }

   func testLoadingIsResetIfError() {
      loadState.setLoading(true)
      XCTAssertTrue(displayState.contains(.loading))
      loadState.setError()
      XCTAssertFalse(displayState.contains(.loading))
   }

   // MARK: - Empty

   func testEmptyIsResetIfReady() {
      loadState.setEmpty()
      XCTAssertTrue(displayState.contains(.empty))
      loadState.setReady()
      XCTAssertFalse(displayState.contains(.empty))
   }

   // MARK: - Ready

   func testReadyIsResetIfEmpty() {
      loadState.setReady()
      XCTAssertTrue(displayState.contains(.ready))
      loadState.setEmpty()
      XCTAssertFalse(displayState.contains(.ready))
   }

   // MARK: - Error

   func testErrorIsResetIfReady() {
      loadState.setError()
      XCTAssertTrue(displayState.contains(.error))
      loadState.setReady()
      XCTAssertFalse(displayState.contains(.error))
   }
}
