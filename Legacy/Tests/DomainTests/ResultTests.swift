//
//  ResultTests.swift
//  Domain
//
//  Created by Ryne Cheow on 15/7/17.
//  Copyright © 2017 Pointwelve. All rights reserved.
//

@testable import Domain
import Foundation
import XCTest

class ResultTests: XCTestCase {}

// MARK: - Equatable

private func ==(lhs: Failure, rhs: Failure) -> Bool {
   switch lhs {
   case .expired: if case .expired = rhs {
      return true
   } else {
      return false
   }
   case .nothing: if case .nothing = rhs {
      return true
   } else {
      return false
   }
   case .offline: if case .offline = rhs {
      return true
   } else {
      return false
   }
   case let .error(lhsError):
      switch rhs {
      case let .error(rhsError): return lhsError.localizedDescription == rhsError.localizedDescription
      default: return false
      }
   }
}

private func == <T: Equatable>(lhs: Result<T>, rhs: Result<T>) -> Bool {
   switch lhs {
   case .content:
      switch rhs {
      case .content: return lhs.contentValue == rhs.contentValue
      default: return false
      }
   case let .page(lhsResult):
      switch rhs {
      case let .page(rhsResult): return lhsResult == rhsResult
      default: return false
      }
   case let .failure(lhsFailure):
      switch rhs {
      case let .failure(rhsFailure): return lhsFailure == rhsFailure
      default: return false
      }
   }
}

// MARK: - Has Content

extension ResultTests {
   func testHasContentForContentWithPartialProgressReturnsTrue() {
      let result = Result.content(.with("content", .partial))
      XCTAssertTrue(result.hasContent)
   }

   func testHasContentForContentWithFullProgressReturnsTrue() {
      let result = Result.content(.with("content", .full))
      XCTAssertTrue(result.hasContent)
   }

   func testHasContentForContentWithLoadingProgressReturnsFalse() {
      let result = Result.content(.with("content", .loading))
      XCTAssertFalse(result.hasContent)
   }

   func testHasContentForFailureWithExpiredReturnsFalse() {
      let result = Result<String>.failure(.expired)
      XCTAssertFalse(result.hasContent)
   }

   func testHasContentForFailureWithNothingReturnsFalse() {
      let result = Result<String>.failure(.nothing)
      XCTAssertFalse(result.hasContent)
   }

   func testHasContentForFailureWithOfflineReturnsFalse() {
      let result = Result<String>.failure(.offline)
      XCTAssertFalse(result.hasContent)
   }

   func testHasContentForFailureWithErrorReturnsFalse() {
      let result = Result<String>.failure(.error(CacheError.invalid))
      XCTAssertFalse(result.hasContent)
   }

   func testHasContentForPageReturnsFalse() {
      let innerResult = Result.content(.with("content", .loading))
      let outerResult = Result.page(innerResult)
      XCTAssertFalse(outerResult.hasContent)
   }
}

// MARK: - Is Loading

extension ResultTests {
   func testIsLoadingForContentWithPartialProgressReturnsFalse() {
      let result = Result.content(.with("content", .partial))
      XCTAssertFalse(result.isLoading)
   }

   func testIsLoadingForContentWithFullProgressReturnsFalse() {
      let result = Result.content(.with("content", .full))
      XCTAssertFalse(result.isLoading)
   }

   func testIsLoadingForContentWithLoadingProgressReturnsTrue() {
      let result = Result.content(.with("content", .loading))
      XCTAssertTrue(result.isLoading)
   }

   func testIsLoadingForFailureWithExpiredReturnsFalse() {
      let result = Result<String>.failure(.expired)
      XCTAssertFalse(result.isLoading)
   }

   func testIsLoadingForFailureWithNothingReturnsFalse() {
      let result = Result<String>.failure(.nothing)
      XCTAssertFalse(result.isLoading)
   }

   func testIsLoadingForFailureWithOfflineReturnsFalse() {
      let result = Result<String>.failure(.offline)
      XCTAssertFalse(result.isLoading)
   }

   func testIsLoadingForFailureWithErrorReturnsFalse() {
      let result = Result<String>.failure(.error(CacheError.invalid))
      XCTAssertFalse(result.isLoading)
   }

   func testIsLoadingForPageReturnsFalse() {
      let innerResult = Result.content(.with("content", .loading))
      let outerResult = Result.page(innerResult)
      XCTAssertFalse(outerResult.isLoading)
   }
}

// MARK: - Is Paged

extension ResultTests {
   func testIsPagedForContentWithPartialProgressReturnsFalse() {
      let result = Result.content(.with("content", .partial))
      XCTAssertFalse(result.isPaged)
   }

   func testIsPagedForContentWithFullProgressReturnsFalse() {
      let result = Result.content(.with("content", .full))
      XCTAssertFalse(result.isPaged)
   }

   func testIsPagedForContentWithLoadingProgressReturnsFalse() {
      let result = Result.content(.with("content", .loading))
      XCTAssertFalse(result.isPaged)
   }

   func testIsPagedForFailureWithExpiredReturnsFalse() {
      let result = Result<String>.failure(.expired)
      XCTAssertFalse(result.isPaged)
   }

   func testIsPagedForFailureWithNothingReturnsFalse() {
      let result = Result<String>.failure(.nothing)
      XCTAssertFalse(result.isPaged)
   }

   func testIsPagedForFailureWithOfflineReturnsFalse() {
      let result = Result<String>.failure(.offline)
      XCTAssertFalse(result.isPaged)
   }

   func testIsPagedForFailureWithErrorReturnsFalse() {
      let result = Result<String>.failure(.error(CacheError.invalid))
      XCTAssertFalse(result.isPaged)
   }

   func testIsPagedForPageReturnsTrue() {
      let innerResult = Result.content(.with("content", .loading))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.isPaged)
   }
}

// MARK: - Is Offline

extension ResultTests {
   func testIsOfflineForContentWithPartialProgressReturnsFalse() {
      let result = Result.content(.with("content", .partial))
      XCTAssertFalse(result.isOffline)
   }

   func testIsOfflineForContentWithFullProgressReturnsFalse() {
      let result = Result.content(.with("content", .full))
      XCTAssertFalse(result.isOffline)
   }

   func testIsOfflineForContentWithLoadingProgressReturnsFalse() {
      let result = Result.content(.with("content", .loading))
      XCTAssertFalse(result.isOffline)
   }

   func testIsOfflineForFailureWithExpiredReturnsFalse() {
      let result = Result<String>.failure(.expired)
      XCTAssertFalse(result.isOffline)
   }

   func testIsOfflineForFailureWithNothingReturnsFalse() {
      let result = Result<String>.failure(.nothing)
      XCTAssertFalse(result.isOffline)
   }

   func testIsOfflineForFailureWithOfflineReturnsTrue() {
      let result = Result<String>.failure(.offline)
      XCTAssertTrue(result.isOffline)
   }

   func testIsOfflineForFailureWithCacheErrorReturnsFalse() {
      let result = Result<String>.failure(.error(CacheError.invalid))
      XCTAssertFalse(result.isOffline)
   }

   func testIsOfflineForFailureWithNetworkErrorReturnsTrue() {
      let result = Result<String>.failure(.error(NSError.networkUnreachableError))
      XCTAssertTrue(result.isOffline)
   }

   func testIsOfflineForPageWithFailureWithNetworkErrorReturnsFalse() {
      let innerResult = Result<String>.failure(.error(NSError.networkUnreachableError))
      let outerResult = Result.page(innerResult)
      XCTAssertFalse(outerResult.isOffline)
   }

   func testIsOfflineForPageWithFailureWithOfflineReturnsFalse() {
      let innerResult = Result<String>.failure(.offline)
      let outerResult = Result.page(innerResult)
      XCTAssertFalse(outerResult.isOffline)
   }
}

// MARK: - Content Value

extension ResultTests {
   func testContentValueForContentWithPartialProgressReturnsValue() {
      let result = Result.content(.with("content", .partial))
      XCTAssertEqual(result.contentValue!, "content")
   }

   func testContentValueForContentWithFullProgressReturnsValue() {
      let result = Result.content(.with("content", .full))
      XCTAssertEqual(result.contentValue!, "content")
   }

   func testContentValueForContentWithLoadingProgressReturnsValue() {
      let result = Result.content(.with("content", .loading))
      XCTAssertEqual(result.contentValue!, "content")
   }

   func testContentValueForFailureWithExpiredReturnsNil() {
      let result = Result<String>.failure(.expired)
      XCTAssertNil(result.contentValue)
   }

   func testContentValueForFailureWithNothingReturnsFalse() {
      let result = Result<String>.failure(.nothing)
      XCTAssertNil(result.contentValue)
   }

   func testContentValueForFailureWithOfflineReturnsTrue() {
      let result = Result<String>.failure(.offline)
      XCTAssertNil(result.contentValue)
   }

   func testContentValueForFailureWithErrorReturnsFalse() {
      let result = Result<String>.failure(.error(CacheError.invalid))
      XCTAssertNil(result.contentValue)
   }

   func testContentValueForPageWithContentWithPartialProgressReturnsNil() {
      let innerResult = Result.content(.with("content", .partial))
      let outerResult = Result.page(innerResult)
      XCTAssertNil(outerResult.contentValue)
   }

   func testContentValueForPageWithContentWithFullProgressReturnsNil() {
      let innerResult = Result.content(.with("content", .full))
      let outerResult = Result.page(innerResult)
      XCTAssertNil(outerResult.contentValue)
   }

   func testContentValueForPageWithContentWithLoadingProgressReturnsNil() {
      let innerResult = Result.content(.with("content", .loading))
      let outerResult = Result.page(innerResult)
      XCTAssertNil(outerResult.contentValue)
   }
}

// MARK: - Flattened

extension ResultTests {
   func testFlattenedContentWithPartialProgressReturnsContentWithPartialProgress() {
      let result = Result.content(.with("content", .partial))
      XCTAssertTrue(result.flattened == result)
   }

   func testFlattenedContentWithFullProgressReturnsContentWithFullProgress() {
      let result = Result.content(.with("content", .full))
      XCTAssertTrue(result.flattened == result)
   }

   func testFlattenedContentWithLoadingProgressReturnsContentWithLoadingProgress() {
      let result = Result.content(.with("content", .loading))
      XCTAssertTrue(result.flattened == result)
   }

   func testFlattenedFailureWithExpiredReturnsFailureWithExpired() {
      let result = Result<String>.failure(.expired)
      XCTAssertTrue(result.flattened == result)
   }

   func testFlattenedFailureWithNothingReturnsFailureWithNothing() {
      let result = Result<String>.failure(.nothing)
      XCTAssertTrue(result.flattened == result)
   }

   func testFlattenedFailureWithOfflineReturnsFailureWithOffline() {
      let result = Result<String>.failure(.offline)
      XCTAssertTrue(result.flattened == result)
   }

   func testFlattenedFailureWithErrorReturnsFailureWithError() {
      let result = Result<String>.failure(.error(CacheError.invalid))
      XCTAssertTrue(result.flattened == result)
   }

   func testFlattenedPageWithContentWithPartialProgressReturnsContentWithPartialProgress() {
      let innerResult = Result.content(.with("content", .partial))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.flattened == innerResult)
   }

   func testFlattenedPageWithContentWithFullProgressReturnsContentWithFullProgress() {
      let innerResult = Result.content(.with("content", .full))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.flattened == innerResult)
   }

   func testFlattenedPageWithContentWithLoadingProgressReturnsContentWithLoadingProgress() {
      let innerResult = Result.content(.with("content", .loading))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.flattened == innerResult)
   }

   func testFlattenedPageOnlyRemovesOneLevelOfNesting() {
      let innerMostResult = Result.content(.with("content", .loading))
      let innerResult = Result.page(innerMostResult)
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.flattened == innerResult)
      XCTAssertTrue(outerResult.flattened.flattened == innerMostResult)
   }

   func testFlattenedPageWithFailureWithExpiredReturnsFailureWithExpired() {
      let innerResult = Result<String>.failure(.expired)
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.flattened == innerResult)
   }

   func testFlattenedPageWithFailureWithNothingReturnsFailureWithNothing() {
      let innerResult = Result<String>.failure(.nothing)
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.flattened == innerResult)
   }

   func testFlattenedPageWithFailureWithOfflineReturnsFailureWithOffline() {
      let innerResult = Result<String>.failure(.offline)
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.flattened == innerResult)
   }

   func testFlattenedPageWithFailureWithErrorReturnsFailureWithError() {
      let innerResult = Result<String>.failure(.error(CacheError.invalid))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.flattened == innerResult)
   }
}

// MARK: - To Load State

extension ResultTests {
   func testFailureWithExpiredReturnsLoadStateExpired() {
      let result = Result<String>.failure(.expired)
      XCTAssertTrue(result.toLoadState() == .expired)
   }

   func testFailureWithNothingReturnsLoadStateEmpty() {
      let result = Result<String>.failure(.nothing)
      XCTAssertTrue(result.toLoadState() == .empty)
   }

   func testFailureWithErrorReturnsLoadStateError() {
      let result = Result<String>.failure(.error(CacheError.invalid))
      XCTAssertTrue(result.toLoadState() == .error)
   }

   func testFailureWithOfflineReturnsLoadStateOffline() {
      let result = Result<String>.failure(.offline)
      XCTAssertTrue(result.toLoadState() == .offline)
   }

   func testContentWithPartialProgressReturnsLoadStateReady() {
      let result = Result.content(.with("content", .partial))
      XCTAssertTrue(result.toLoadState() == .ready)
   }

   func testContentWithFullProgressReturnsLoadStateReady() {
      let result = Result.content(.with("content", .full))
      XCTAssertTrue(result.toLoadState() == .ready)
   }

   func testContentWithLoadingProgressReturnsLoadStateLoading() {
      let result = Result.content(.with("content", .loading))
      XCTAssertTrue(result.toLoadState() == .loading)
   }

   // MARK: - Paged

   func testPageWithFailureWithExpiredReturnsLoadStateExpired() {
      let innerResult = Result<String>.failure(.expired)
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.toLoadState() == .pageExpired)
   }

   func testPageWithFailureWithNothingReturnsLoadStateEmpty() {
      let innerResult = Result<String>.failure(.nothing)
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.toLoadState() == .pageEmpty)
   }

   func testPageWithFailureWithErrorReturnsLoadStateError() {
      let innerResult = Result<String>.failure(.error(CacheError.invalid))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.toLoadState() == .pageError)
   }

   func testPageWithFailureWithOfflineReturnsLoadStateOffline() {
      let innerResult = Result<String>.failure(.offline)
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.toLoadState() == .offline)
   }

   func testPageWithContentWithPartialProgressReturnsLoadStatePageAvailable() {
      let innerResult = Result.content(.with("content", .partial))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.toLoadState() == .pageAvailable)
   }

   func testPageWithContentWithFullProgressReturnsLoadStateReady() {
      let innerResult = Result.content(.with("content", .full))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.toLoadState() == .ready)
   }

   func testPageWithContentWithLoadingProgressReturnsLoadStatePageLoading() {
      let innerResult = Result.content(.with("content", .loading))
      let outerResult = Result.page(innerResult)
      XCTAssertTrue(outerResult.toLoadState() == .pageLoading)
   }
}
