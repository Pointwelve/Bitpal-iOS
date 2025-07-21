//
//  VerySimpleTests.swift
//  Bitpal-v2Tests
//
//  Created by Claude on 20/7/25.
//

import XCTest
@testable import Bitpal_v2

final class VerySimpleTests: XCTestCase {
    
    func testCurrencyCreation() {
        let currency = Currency.bitcoin()
        
        XCTAssertEqual(currency.id, "btc")
        XCTAssertEqual(currency.name, "Bitcoin")
        XCTAssertEqual(currency.symbol, "BTC")
        XCTAssertEqual(currency.displaySymbol, "₿")
    }
    
    func testExchangeCreation() {
        let exchange = Exchange.binance()
        
        XCTAssertEqual(exchange.id, "binance")
        XCTAssertEqual(exchange.name, "Binance")
        XCTAssertTrue(exchange.isActive)
    }
    
    func testConfigurationValidation() {
        let config = Configuration()
        
        XCTAssertTrue(config.isValid)
        XCTAssertFalse(config.apiKey.isEmpty)
        XCTAssertFalse(config.apiHost.isEmpty)
        XCTAssertFalse(config.socketHost.isEmpty)
    }
}