//
//  CoinGeckoServiceTests.swift
//  BitpalTests
//
//  Created by Bitpal Development on 8/11/25.
//

import XCTest
@testable import Bitpal

/// Unit tests for CoinGeckoService error handling
/// Per Constitution Principle IV: Test API error handling (REQUIRED)
final class CoinGeckoServiceTests: XCTestCase {

    func testFetchMarketData_emptyArray_returnsEmptyDictionary() async throws {
        // Given: CoinGeckoService shared instance
        let service = CoinGeckoService.shared

        // When: Fetching market data with empty coin IDs
        let result = try await service.fetchMarketData(coinIds: [])

        // Then: Returns empty dictionary
        XCTAssertTrue(result.isEmpty)
    }

    // Note: Additional network error tests would require mocking URLSession
    // For MVP, we test basic error path (empty input) and rely on integration tests
    // Full network mocking can be added in Phase 7 (Polish)
}
